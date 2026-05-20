import base64
import json
import logging
import os
import random
from typing import Any

import urllib3

URL_LAMBDA_INFERENCE = os.getenv("URL_LAMBDA_INFERENCE", "")
ITEM_LIMIT = os.getenv("ITEM_LIMIT", 5)
RANDOM_SEED = os.getenv("RANDOM_SEED", 42)

random.seed(RANDOM_SEED)

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def decode_record(record: bytes) -> dict:
    """Decodes a base64-encoded record received from Kinesis Data Streams.

    Args:
        record: Raw base64-encoded bytes from the Kinesis record payload.

    Returns:
        Decoded event data as a dictionary.
    """
    string_data = base64.b64decode(record).decode("utf-8")
    return json.loads(string_data)


def get_user_embedding(url: str, data: list[dict]) -> Any:
    """Requests a user embedding vector from the inference API.

    Args:
        url:  Base URL of the inference Lambda function.
        data: List of user feature dictionaries to embed.

    Returns:
        List of embedding dictionaries returned by the inference API.
    """
    http = urllib3.PoolManager()
    response = http.request(
        "POST",
        f"{url}/user_embeddings",
        headers={"accept": "application/json", "Content-Type": "application/json"},
        body=json.dumps(data).encode("utf-8"),
    )
    return json.loads(response.data)


def get_item_from_user(url: str, data: dict, item_limit: int) -> Any:
    """Recommends items for a given user embedding vector.

    Args:
        url:        Base URL of the inference Lambda function.
        data:       User embedding vector dictionary.
        item_limit: Maximum number of items to recommend.

    Returns:
        List of recommended item dictionaries, each with id and score.
    """
    http = urllib3.PoolManager()
    response = http.request(
        "POST",
        f"{url}/items_from_user?limit={item_limit}",
        headers={"accept": "application/json", "Content-Type": "application/json"},
        body=json.dumps(data).encode("utf-8"),
    )
    return json.loads(response.data)


def get_item_from_item(url: str, item_id: str, item_limit: int) -> Any:
    """Recommends items similar to a given product.

    Args:
        url:        Base URL of the inference Lambda function.
        item_id:    Product code of the seed item.
        item_limit: Maximum number of similar items to return.

    Returns:
        List of similar item dictionaries returned by the inference API.
    """
    http = urllib3.PoolManager()
    response = http.request(
        "GET",
        f"{url}/items_from_item?item_id={item_id}&limit={item_limit}",
        headers={"accept": "application/json"},
    )
    return json.loads(response.data)


def lambda_handler(event, context):
    logger.info(f"Stream transformation invoked — sample records: {event['records'][:2]}")

    output = []
    for record in event["records"]:
        payload = decode_record(record["data"])

        user_features = [
            {
                "city": payload.get("city"),
                "country": payload.get("country"),
                "creditlimit": payload.get("credit_limit"),
            }
        ]

        # Compute user embedding and retrieve user-based recommendations
        user_embedding = get_user_embedding(url=URL_LAMBDA_INFERENCE, data=user_features)
        recommended_items = get_item_from_user(
            url=URL_LAMBDA_INFERENCE,
            data=user_embedding[0],
            item_limit=int(ITEM_LIMIT),
        )

        # Pick a random item from the user's browse history and find similar items
        selected_item = random.choice(payload["browse_history"])
        similar_items = get_item_from_item(
            url=URL_LAMBDA_INFERENCE,
            item_id=selected_item["product_code"],
            item_limit=int(ITEM_LIMIT),
        )

        payload["recommended_items"] = recommended_items
        payload["similar_items"] = {
            "product_code": selected_item["product_code"],
            "similar_items": similar_items,
        }

        output.append({
            "recordId": record["recordId"],
            "result": "Ok",
            "data": base64.b64encode(json.dumps(payload).encode("utf-8")).decode("utf-8"),
        })

    logger.info(f"Transformation complete — sample output: {output[:2]}")
    return {"records": output}
