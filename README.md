# 🔭 SRE Observability — Zero to Hero

[![Lab CI](https://github.com/KeninP/sre-observability-zero-to-hero/actions/workflows/lab-ci.yml/badge.svg)](https://github.com/KeninP/sre-observability-zero-to-hero/actions/workflows/lab-ci.yml)

A hands-on path from "what is a trace?" to running observability for Kubernetes in production — written by an SRE who does this day to day (Dynatrace, OpenTelemetry, AKS/EKS, P1/P2 incidents).

Every chapter is **concept → lab → what it looks like in production**. The local lab runs with one command and is tested end-to-end in CI on every push.

## 🗺️ Roadmap

| # | Chapter | What you'll learn | Status |
|---|---|---|---|
| 01 | [Fundamentals](01-fundamentals/) | Metrics, logs, traces · golden signals · RED/USE · SLI/SLO/error budgets | ✅ |
| 02 | [OpenTelemetry lab](02-opentelemetry-lab/) | Instrument a service, run the OTel Collector, see data in Prometheus, Grafana and Jaeger | ✅ |
| 03 | [Kubernetes observability](03-kubernetes-observability/) | Collector on a cluster, k8s attributes, the signals that matter for pods and nodes | ✅ |
| 04 | [Dynatrace + OTLP](04-dynatrace/) | Ship OpenTelemetry to Dynatrace, DQL for logs/spans, SLOs, alerting to ServiceNow | ✅ |
| 05 | [Incident response](05-incident-response/) | Triage flow, CrashLoopBackOff/OOMKilled playbook, runbook + postmortem templates | ✅ |
| 06 | Alerting that doesn't page you at 3 a.m. for nothing | Burn-rate alerts, routing, noise reduction | ⏳ |
| 07 | Infrastructure as Code for observability | Terraform for dashboards, alerts and cloud monitoring | ⏳ |

## 🚀 Quick start

```bash
git clone https://github.com/KeninP/sre-observability-zero-to-hero.git
cd sre-observability-zero-to-hero/02-opentelemetry-lab
docker compose up -d --build
```

| Tool | URL |
|---|---|
| Demo service | http://localhost:8080 |
| Grafana | http://localhost:3000 (anonymous viewer) |
| Prometheus | http://localhost:9090 |
| Jaeger | http://localhost:16686 |

## 🧭 How to use this repo

1. Read the chapter's concept section — short, plain English.
2. Run the lab and **break something on purpose** (each lab has exercises).
3. Read "In production" to see how the same idea scales to real clusters.

## 🤝 Contributing

Found a mistake or want a chapter? Open an issue or a PR — contributions are welcome.

---

Maintained by [Kenin Paradesi](https://www.linkedin.com/in/kenin-paradeshi7788/) · Site Reliability Engineer
