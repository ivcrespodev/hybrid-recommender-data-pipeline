import sys
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from awsglue.utils import getResolvedOptions

def spark_sql_query(glue_context, query, mapping, transformation_ctx) -> DynamicFrame:
    """Registers DynamicFrames as temporary views and executes a Spark SQL query."""
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glue_context, transformation_ctx)

# 1. Parse runtime arguments passed dynamically by the Terraform/orchestration layer
args = getResolvedOptions(
    sys.argv, ["JOB_NAME", "glue_connection", "glue_database", "target_path"]
)

# 2. Initialize Spark, Glue context, and track telemetry lifecycle
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# 3. Ingest source tables from the MySQL Relational Operational Data Store (ODS)
products_node = glueContext.create_dynamic_frame.from_options(
    connection_type="mysql",
    connection_options={
        "useConnectionProperties": "true",
        "dbtable": "classicmodels.products",
        "connectionName": args["glue_connection"],
    },
    transformation_ctx="products_node",
)

customers_node = glueContext.create_dynamic_frame.from_options(
    connection_type="mysql",
    connection_options={
        "useConnectionProperties": "true",
        "dbtable": "classicmodels.customers",
        "connectionName": args["glue_connection"],
    },
    transformation_ctx="customers_node",
)

ratings_node = glueContext.create_dynamic_frame.from_options(
    connection_type="mysql",
    connection_options={
        "useConnectionProperties": "true",
        "dbtable": "classicmodels.ratings",
        "connectionName": args["glue_connection"],
    },
    transformation_ctx="ratings_node",
)

# 4. Consolidate analytical dimensions via distributed relational Joins
sql_join_query = """
SELECT 
    r.customerNumber,
    c.city,
    c.state,
    c.postalCode,
    c.country,
    c.creditLimit,
    r.productCode,
    p.productLine,
    p.productScale,
    p.quantityInStock,
    p.buyPrice,
    p.MSRP,
    r.productRating
FROM ratings r 
JOIN products p ON p.productCode = r.productCode 
JOIN customers c ON c.customerNumber = r.customerNumber;
"""

join_node = spark_sql_query(
    glueContext,
    query=sql_join_query,
    mapping={
        "ratings": ratings_node,
        "products": products_node,
        "customers": customers_node,
    },
    transformation_ctx="join_node",
)

# 5. Partition features and write analytical datasets to the S3 Data Lake (Parquet/Snappy)
s3_upload_node = glueContext.getSink(
    path=f"{args['target_path']}/ratings_ml_training/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["customerNumber"],
    enableUpdateCatalog=True,
    transformation_ctx="s3_upload_node",
)

s3_upload_node.setCatalogInfo(
    catalogDatabase=args["glue_database"],
    catalogTableName="ratings_ml_training",
)

s3_upload_node.setFormat("glueparquet", compression="snappy")
s3_upload_node.writeFrame(join_node)

# 6. Commit job state to finalized status
job.commit()
