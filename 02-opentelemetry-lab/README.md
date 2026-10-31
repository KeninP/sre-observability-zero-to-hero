# 02 · OpenTelemetry Lab

A one-command lab: an instrumented Python "checkout" service sends traces, metrics and logs through the **OpenTelemetry Collector** to **Jaeger**, **Prometheus** and **Grafana**. A load generator keeps traffic flowing so there's always something to look at.

```
                      OTLP gRPC :4317
 ┌─────────┐  ┌──────────────────┐  ┌───────────────────────────┐
 │ loadgen │─►│ checkout-service │─►│     OTel Collector        │
 └─────────┘  │ (Flask + OTel    │  │ memory_limiter → resource │
              │  auto-instrument)│  │ → batch                   │
              └──────────────────┘  └───┬──────────┬────────┬───┘
                                traces  │  metrics │   logs │
                                        ▼          ▼        ▼
                                    Jaeger   Prometheus   debug
                                        ▲      │  ▲ alerts  (collector stdout)
                                        └──── Grafana
```

## Run it

```bash
docker compose up -d --build
docker compose ps
```

| Open | What to look at |
|---|---|
| http://localhost:3000 | **Checkout service — RED + SLO** dashboard (home page) |
| http://localhost:16686 | Jaeger → service `checkout-service` → *Find Traces* |
| http://localhost:9090/alerts | The two SLO alerts and their state |
| `docker compose logs -f otel-collector` | Logs arriving via OTLP |

Stop with `docker compose down`.

## What's going on

- **No telemetry code for HTTP.** `opentelemetry-instrument` auto-instruments Flask from `OTEL_*` env vars ([docker-compose.yml](docker-compose.yml)). The app only adds two **custom spans** (`inventory.reserve`, `payment.charge`) and one **custom metric** (`shop.orders`).
- **The Collector is the control point.** Apps send everything to one place; the collector adds `deployment.environment`, protects itself with `memory_limiter`, batches, and routes each signal to a backend. Swapping Jaeger for Dynatrace is a config change, not a code change ([chapter 04](../04-dynatrace/)).
- **Metric naming.** OTel `http.server.duration` (ms) becomes `http_server_duration_milliseconds_{bucket,count,sum}` in Prometheus; `shop.orders` becomes `shop_orders_total`.

## 🧪 Exercises — break it on purpose

1. **Trigger the error-rate alert.** Set `ERROR_RATE: "0.3"` in `docker-compose.yml`, run `docker compose up -d app`, and watch:
   - the Error-rate stat go red and the SLO budget fall,
   - `CheckoutHighErrorRate` go *pending* → *firing* after 2 minutes at http://localhost:9090/alerts,
   - failed traces in Jaeger (filter `error=true`) and `payment failed` log lines in the collector output.
2. **Find a latency problem with traces, not guesses.** Set `SLOW_RATE: "0.5"`. p95 jumps — open a slow trace in Jaeger. Which span owns the time? What attribute tells you why?
3. **Lose the collector.** `docker compose stop otel-collector` for a minute, then start it. What happens to the dashboards? What does the app log? Why do production setups run collectors as a DaemonSet *and* a gateway?
4. **Write your own PromQL.** Requests per second per status code, and the ratio of `shop_orders_total{result="failed"}` to all orders.
5. **Cardinality trap.** Add `{"order_id": order_id}` as an attribute on `orders.add(...)`. Rebuild and count series with `count(shop_orders_total)`. Revert it.

## In production

- Run the collector as a **DaemonSet** (per-node, close to the app) and optionally a **gateway** Deployment (central auth, tail sampling, fan-out).
- Sample traces (head sampling in the SDK, or tail sampling on errors/slow requests in the gateway) — 100 % tracing at scale is expensive.
- Alerts page on **symptoms** (error rate, latency SLOs). Everything else is a ticket or a dashboard.

⬅️ [01 · Fundamentals](../01-fundamentals/) · ➡️ [03 · Kubernetes observability](../03-kubernetes-observability/)
