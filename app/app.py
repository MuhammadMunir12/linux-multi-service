from flask import Flask, jsonify, request
import logging
import os
from datetime import datetime, timezone

app = Flask(__name__)

LOG_FILE = "/var/log/webapp/app.log"

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)

logger = logging.getLogger(__name__)


@app.route("/")
def index():
    logger.info(
        "Request received: method=%s path=%s remote_addr=%s",
        request.method,
        request.path,
        request.remote_addr,
    )

    return jsonify(
        {
            "service": "linux-multi-service",
            "status": "running",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
    )


@app.route("/health")
def health():
    logger.info(
        "Health check: remote_addr=%s",
        request.remote_addr,
    )

    return jsonify(
        {
            "status": "healthy",
            "service": "webapp",
        }
    ), 200


if __name__ == "__main__":
    app.run(
        host="127.0.0.1",
        port=3000,
    )
