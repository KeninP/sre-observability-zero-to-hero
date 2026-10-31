# 01 · Observability Fundamentals

**Monitoring** tells you *that* something is wrong. **Observability** lets you ask *why* — including questions you didn't think of before the incident.

## The three signals

| Signal | What it is | Good for | Example |
|---|---|---|---|
| **Metrics** | Numbers over time, cheap to store | Dashboards, alerts, trends | `http_requests_total`, CPU %, p95 latency |
| **Logs** | Timestamped events with detail | The "what exactly happened" | `ERROR payment declined order=123` |
| **Traces** | One request's path across services | Finding *where* time or errors come from | checkout → payment → db (420 ms in db) |

They're most useful **linked**: an alert (metric) → the slow traces in that window → the logs for that trace ID. OpenTelemetry puts the same `trace_id` and resource attributes (`service.name`, `k8s.namespace.name`…) on all three so tools can join them.

## What to measure

**Golden signals** (Google SRE book) — for anything user-facing:

1. **Latency** — how long requests take (track successful and failed separately)
2. **Traffic** — requests per second
3. **Errors** — rate of failed requests
4. **Saturation** — how "full" the service is (CPU, memory, queue depth, connection pool)

Two shortcuts:

- **RED** for services: **R**ate, **E**rrors, **D**uration
- **USE** for resources (nodes, disks, DBs): **U**tilisation, **S**aturation, **E**rrors

## SLI, SLO, error budget

| Term | Meaning | Example |
|---|---|---|
| **SLI** (indicator) | A measured ratio of good events | successful checkout requests ÷ all checkout requests |
| **SLO** (objective) | The target for the SLI over a window | 99.5 % over 30 days |
| **Error budget** | How much failure the SLO allows | 0.5 % of requests may fail |

**Error budget maths** for a 99.5 % / 30-day SLO:

- Time view: 30 d × 24 h × 60 min × 0.005 = **216 minutes** of full outage allowed
- Request view: at 1 M requests/month → **5,000** failed requests allowed

Budget left → ship features. Budget burning fast → freeze risky changes and fix reliability. That's the deal an SLO creates between dev and ops.

> **Tip:** pick SLOs from what users feel (checkout works, page loads) — not from CPU. CPU is a *cause*, not a *symptom*.

## Cardinality — the silent cost

Every unique combination of label values is a new time series. `user_id` as a metric label on 1 M users = 1 M series = slow queries and a big bill. Put high-cardinality data on **traces and logs**, keep metric labels bounded (service, route, status code, namespace).

## ✅ Check yourself

- Your p95 latency is fine but users complain. Which signal would you look at next, and why?
- Error budget is 60 % used after week 1 of the month. What do you do?
- Why is `pod_name` a risky metric label in a cluster with frequent deployments?

➡️ Next: [02 · OpenTelemetry lab](../02-opentelemetry-lab/)
