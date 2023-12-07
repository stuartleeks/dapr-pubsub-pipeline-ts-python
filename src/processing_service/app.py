import time
from flask import Flask, request
import json
import logging
import os
import string

app = Flask(__name__)
processing_delay = float(os.getenv("DELAY", "2"))
shift_amount = int(os.getenv("SHIFT_AMOUNT", "1"))

port = int(os.getenv("APP_PORT", "6003"))

logging.basicConfig(level=logging.INFO)


def caesar_shift(plaintext, shift):
    alphabet = string.ascii_letters
    shifted_alphabet = alphabet[shift:] + alphabet[:shift]
    trans_table = str.maketrans(alphabet, shifted_alphabet)
    return plaintext.translate(trans_table)


@app.route("/process", methods=["POST"])
def do_stuff1():
    logger = logging.getLogger("process")

    data = request.json

    # test if data (dictionary) has key 'actions'
    id = data.get("id", "<none>")
    log_extra = {"id": id}
    input_content = data["content"]

    logger.info(
        f"[{id}] process triggered: " + json.dumps(data), extra=log_extra
    )

    logger.info(f"[{id}] Sleeping {processing_delay}...", extra=log_extra)
    time.sleep(processing_delay)
    logger.info(f"[{id}] Done...", extra=log_extra)

    return (
        json.dumps({"success": True, "result": caesar_shift(input_content, shift_amount)}),
        200,
        {"ContentType": "application/json"},
    )


print(f"Starting processor on port {port}", flush=True  )
app.run(port=port)
