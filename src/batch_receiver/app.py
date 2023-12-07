import time
from flask import Flask, request, jsonify
from cloudevents.http import from_http
from dapr.clients import DaprClient
import json
import os

dapr_client = DaprClient()

# Using Flask here, but there are various options: https://docs.dapr.io/developing-applications/sdks/python/python-sdk-extensions/
app = Flask(__name__)

app_port = os.getenv("APP_PORT", "6001")

source_topic = "input-batches"
destination_topic = "messages"
# TODO: get topic names from env vars


# Register Dapr pub/sub subscriptions
@app.route("/dapr/subscribe", methods=["GET"])
def subscribe():
    subscriptions = [
        {"pubsubname": "pubsub", "topic": source_topic, "route": "input-batch"}
    ]
    print("Dapr pub/sub is subscribed to: " + json.dumps(subscriptions))
    return jsonify(subscriptions)


# Dapr subscription in /dapr/subscribe sets up this route
@app.route("/input-batch", methods=["POST"])
def orders_subscriber():
    event = from_http(request.headers, request.get_data())
    event_id = event.data["id"]
    data = event.data["data"]
    print(f"batch_receiver: got message: {event_id}", flush=True)
    for index, message in enumerate(data.split("\n")):
        dapr_client.publish_event(
            pubsub_name="pubsub",
            topic_name=destination_topic,
            data=json.dumps(
                {"id": f"{event_id}-{index}", "batch_id": event_id, "data": message}
            ),
        )
    return json.dumps({"success": True}), 200, {"ContentType": "application/json"}


app.run(port=app_port)
