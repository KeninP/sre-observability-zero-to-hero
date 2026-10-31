"""A tiny "checkout" service used to generate realistic telemetry.

Failure behaviour is driven by env vars so you can break it on purpose:
  ERROR_RATE      fraction of /checkout calls that fail with 500 (default 0.02)
  SLOW_RATE       fraction of /checkout calls that hit a slow dependency (default 0.05)
  SLOW_MS         how slow that dependency is, in ms (default 800)
"""
import logging
import os
import random
import time

from flask import Flask, jsonify
from opentelemetry import metrics, trace

ERROR_RATE = float(os.getenv("ERROR_RATE", "0.02"))
SLOW_RATE = float(os.getenv("SLOW_RATE", "0.05"))
SLOW_MS = int(os.getenv("SLOW_MS", "800"))

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("checkout")

tracer = trace.get_tracer("checkout")
meter = metrics.get_meter("checkout")
orders = meter.create_counter("shop.orders", unit="{order}", description="Orders processed, by result")

app = Flask(__name__)


@app.get("/")
def health():
    return jsonify(status="ok")


@app.get("/checkout")
def checkout():
    order_id = random.randint(10000, 99999)

    # Child spans show up as separate steps in the Jaeger waterfall
    with tracer.start_as_current_span("inventory.reserve") as span:
        span.set_attribute("order.id", order_id)
        time.sleep(random.uniform(0.005, 0.03))

    with tracer.start_as_current_span("payment.charge") as span:
        if random.random() < SLOW_RATE:
            span.set_attribute("payment.slow_path", True)
            time.sleep(SLOW_MS / 1000)
        else:
            time.sleep(random.uniform(0.01, 0.05))

        if random.random() < ERROR_RATE:
            span.set_status(trace.StatusCode.ERROR, "card declined by provider")
            orders.add(1, {"result": "failed"})
            log.error("payment failed order_id=%s", order_id)
            return jsonify(error="payment failed", order_id=order_id), 500

    orders.add(1, {"result": "success"})
    log.info("order placed order_id=%s", order_id)
    return jsonify(status="placed", order_id=order_id)
