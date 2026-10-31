# 04 · Dynatrace + OpenTelemetry

Dynatrace gives you two ways in: **OneAgent** (auto-instruments hosts and pods) and **OTLP ingest** (anything that speaks OpenTelemetry). Most real estates use both — OneAgent for the platform, OTLP for services and teams that are already instrumented, or for logs shipped by the OTel Collector.

## Send the lab to Dynatrace

1. Create an access token with scopes `openTelemetryTrace.ingest`, `metrics.ingest`, `logs.ingest`.
2. Use [collector-dynatrace.yaml](collector-dynatrace.yaml) instead of the lab's collector config and set:

   ```bash
   export DT_ENV_URL=https://<your-env-id>.live.dynatrace.com
   export DT_API_TOKEN=<token>     # never commit this - use a secret store
   ```

3. Two things that trip people up:
   - **Delta metrics.** Dynatrace ingests OTLP metrics as *delta* temporality. The `cumulativetodelta` processor converts what the SDK sends.
   - **The endpoint is `/api/v2/otlp`** — the exporter appends `/v1/traces`, `/v1/metrics`, `/v1/logs` itself.

On Kubernetes, put the token in a Secret (or Azure Key Vault / AWS Secrets Manager via CSI driver) and reference it as an env var on the collector.

## DQL cheat sheet

DQL is the query language for Dynatrace Grail. Field names below follow OpenTelemetry semantic conventions — check them against your own tenant with `fetch logs | limit 10` first.

**Errors by deployment in a namespace (last hour)**

```sql
fetch logs, from: now() - 1h
| filter k8s.namespace.name == "shop" and loglevel == "ERROR"
| summarize errors = count(), by: { k8s.deployment.name }
| sort errors desc
```

**Latency and volume per operation for one service**

```sql
fetch spans, from: now() - 30m
| filter service.name == "checkout-service"
| summarize requests = count(), p95 = percentile(duration, 95), by: { span.name }
| sort p95 desc
```

**Error rate over time**

```sql
fetch spans, from: now() - 6h
| filter service.name == "checkout-service" and span.kind == "server"
| makeTimeseries total = count(), failed = countIf(span.status_code == "error"), interval: 5m
| fieldsAdd error_rate = failed[] / total[]
```

### Find zero-traffic namespaces

Namespaces that served no requests for a week are cleanup candidates (cost and cluster sprawl). Join the namespace inventory against span traffic and keep the ones with no match:

```sql
fetch dt.entity.cloud_application_namespace
| fields namespace = entity.name
| lookup [
    fetch spans, from: now() - 7d
    | summarize requests = count(), by: { k8s.namespace.name }
  ], sourceField: namespace, lookupField: k8s.namespace.name, prefix: "traffic."
| filter isNull(traffic.requests)
| sort namespace asc
```

Run it from a scheduled pipeline (Azure DevOps, GitHub Actions) via the Dynatrace API and open a ticket — or label the namespace — rather than deleting automatically. Exclude system namespaces (`kube-system`, `dynatrace`, ingress) and anything that only runs batch jobs.

## SLOs in Dynatrace

- Define the SLI on **service-level** data: success rate of the `checkout` endpoint, or the % of requests under 500 ms.
- Pick a window that matches how you report (rolling 7 or 30 days).
- Alert on **burn rate**, not on the SLO value — "we'll exhaust the monthly budget in 2 days" is actionable; "SLO is at 99.41 %" is not.

## Alerting → ServiceNow

```
Davis problem / metric event  ─►  Alerting profile (severity, management zone, delay)
                              ─►  Problem notification (ServiceNow integration)
                              ─►  Incident auto-created with P1/P2 mapping
```

Tips from running this in production:

- Scope alerting profiles by **management zone** (team / app) so each team gets only its own problems.
- Add a short **delay** (e.g. 5–10 min) for non-critical severities — most flaps resolve themselves.
- Put the runbook link in the problem description so on-call starts from a known path ([chapter 05](../05-incident-response/)).

⬅️ [03 · Kubernetes observability](../03-kubernetes-observability/) · ➡️ [05 · Incident response](../05-incident-response/)
