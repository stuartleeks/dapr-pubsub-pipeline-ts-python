import time
from flask import Flask, request, jsonify
from cloudevents.http import from_http
from dapr.clients import DaprClient
import json
import os

dapr_client = DaprClient()

# Using Flask here, but there are various options: https://docs.dapr.io/developing-applications/sdks/python/python-sdk-extensions/
app = Flask(__name__)

app_port = os.getenv("APP_PORT", "6002")

source_topic = "messages"
# TODO: get topic names from env vars


# Register Dapr pub/sub subscriptions
@app.route("/dapr/subscribe", methods=["GET"])
def subscribe():
    subscriptions = [
        {"pubsubname": "pubsub", "topic": source_topic, "route": "process-message"}
    ]
    print("Dapr pub/sub is subscribed to: " + json.dumps(subscriptions))
    return jsonify(subscriptions)


# Dapr subscription in /dapr/subscribe sets up this route
@app.route("/process-message", methods=["POST"])
def orders_subscriber():
    event = from_http(request.headers, request.get_data())
    raw_data = event.data
    data = json.loads(raw_data)
    print(f"message_processor: got message: {data}", flush=True)
    event_id = data["id"]
    message = data["data"]
    print(f"message_processor: got message: {event_id}", flush=True)

    resp = dapr_client.invoke_method(
        app_id="processing_service",
        method_name="process",
        http_verb="POST",
        data=json.dumps({"id": event_id, "content": message}),
        content_type="application/json",
    )
    print(f"message_processor: got response: {resp.text}", flush=True)
    return json.dumps({"success": True}), 200, {"ContentType": "application/json"}


app.run(port=app_port)
