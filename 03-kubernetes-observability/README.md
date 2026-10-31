# 03 · Kubernetes Observability

Same ideas as the lab, but on a cluster (AKS, EKS, minikube, kind) where pods come and go every deploy.

## Architecture

```
 node 1                          node 2
 ┌───────────────────────┐      ┌───────────────────────┐
 │ checkout pod ─┐       │      │ payment pod ─┐        │
 │ checkout pod ─┤ OTLP  │      │              │ OTLP   │
 │               ▼       │      │              ▼        │
 │  otel-agent (DaemonSet)│     │  otel-agent (DaemonSet)│
 │  + kubelet metrics     │     │  + kubelet metrics     │
 │  + /var/log/pods       │     │  + /var/log/pods       │
 └──────────┬─────────────┘     └──────────┬─────────────┘
            └──────────────┬───────────────┘
                           ▼
          backend (Dynatrace / Prometheus / Grafana / ...)
```

- **DaemonSet agent** — one collector per node. Apps send OTLP to the node IP; the agent also scrapes the kubelet and tails container logs.
- **`k8sattributes` processor** — looks up the sending pod and stamps `k8s.namespace.name`, `k8s.deployment.name`, `k8s.node.name` on every span, metric and log. This is what lets you filter "all errors in namespace `shop`".
- Optional **gateway** Deployment for central auth, tail sampling and fan-out to multiple backends.

## Deploy

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm install otel-agent open-telemetry/opentelemetry-collector \
  -n observability --create-namespace -f collector-values.yaml

kubectl apply -f manifests/
kubectl -n observability logs ds/otel-agent-opentelemetry-collector-agent | head
```

Files:

- [collector-values.yaml](collector-values.yaml) — DaemonSet mode with the `kubernetesAttributes`, `kubeletMetrics` and `logsCollection` presets
- [manifests/](manifests/) — sample `checkout` Deployment wired to the node-local agent via the downward API (`status.hostIP`)

## Signals that matter on Kubernetes

| Question | Signal |
|---|---|
| Is the service healthy for users? | RED metrics per service (from traces/HTTP metrics) |
| Are pods restarting? | `kube_pod_container_status_restarts_total` / restart count — and *why*: `OOMKilled`, `Error`, `CrashLoopBackOff` |
| Are we about to run out? | Container memory vs **limit**, CPU throttling, node allocatable vs requested |
| Did the last deploy break it? | Error rate / latency split by `service.version` |
| Is a namespace even used? | Requests per namespace over 7 days — zero traffic = cleanup candidate ([DQL example](../04-dynatrace/#find-zero-traffic-namespaces)) |

## Common gotchas

- **Memory limit without a request** → scheduler packs pods too tightly → OOMKills under load. Set both.
- **Readiness ≠ liveness.** A failing liveness probe *restarts* the pod; use readiness for "not ready for traffic yet".
- **Missing k8s attributes** usually means the collector's ServiceAccount lacks RBAC for pods/replicasets — the Helm preset creates it for you.
- **Logs without trace IDs** can't be joined to traces. Use the OTel logging instrumentation (as the lab does) or log the `trace_id` field.

⬅️ [02 · OpenTelemetry lab](../02-opentelemetry-lab/) · ➡️ [04 · Dynatrace + OTLP](../04-dynatrace/)
