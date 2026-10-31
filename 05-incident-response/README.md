# 05 · Incident Response

Observability pays off at 3 a.m. This chapter is the path from *alert fired* to *service restored* to *it won't happen again*.

## The flow

```
Detect ──► Triage ──► Mitigate ──► Resolve ──► Learn
alert /     impact,     restore      confirm     postmortem,
synthetic   priority,   service      in SLO      action items
            comms       first
```

**Mitigate before you root-cause.** Rolling back a bad deploy in 2 minutes beats a perfect diagnosis in 40.

## Priority guide

| Priority | Typical meaning | Response |
|---|---|---|
| **P1** | Core user journey down or data at risk | Page on-call, open bridge, updates every 30 min |
| **P2** | Degraded / partial outage, workaround exists | On-call works it in hours, updates every 1–2 h |
| **P3** | Minor, no SLO impact | Ticket, next business day |

## Kubernetes playbook

| You see | Usual cause | First checks | Fix |
|---|---|---|---|
| `CrashLoopBackOff` | App exits on start: bad config, missing secret, dependency down | `kubectl logs <pod> --previous`, `kubectl describe pod` | Fix config/secret; if the dependency recovered, restart the rollout |
| `OOMKilled` (exit 137) | Memory limit too low, or a leak | `kubectl describe pod` → *Last State*, memory graph vs limit | Raise limit with evidence, or roll back the leaking version |
| `ImagePullBackOff` | Wrong tag, registry auth, rate limit | `kubectl describe pod` → Events | Fix tag / pull secret / registry access |
| `Pending` | No node fits the requests, PVC not bound | `kubectl describe pod` → *FailedScheduling* | Right-size requests, add nodes, fix storage class |
| Readiness failing, no restarts | App up but a dependency is slow/down | Probe endpoint, traces of the readiness path | Fix the dependency; make readiness check only what the pod owns |
| Error spike right after deploy | Regression | Error rate split by `service.version` | `kubectl rollout undo` |

## Scripts

- [scripts/k8s-triage.sh](scripts/k8s-triage.sh) — read-only snapshot of a namespace: unhealthy pods, restart reasons, warning events, resource usage, rollout status.
- [scripts/restart-unhealthy.sh](scripts/restart-unhealthy.sh) — dry-run-by-default **rolling restart** that annotates the Deployment with who/when. Wired into a pipeline, it gives on-call a one-step, audited recovery instead of ad-hoc `kubectl delete pod`.

> Why `rollout restart` and not scale to 0 and back? Scaling to 0 takes the service fully down; a rolling restart replaces pods while respecting the Deployment's `maxUnavailable`. Scale to 0 only when pods must *not* run side by side (e.g. a stuck singleton consumer).

## Templates

- [Runbook template](templates/runbook-template.md) — one per alert; link it from the alert itself.
- [Postmortem template](templates/postmortem-template.md) — blameless, with action items typed as *prevent / detect / mitigate*.

## Habits that make incidents shorter

- Every alert has an owner and a runbook link — or it gets deleted.
- Deploy markers on dashboards ("what changed?" is the first question).
- Synthetic checks on critical endpoints, so you hear about outages before users do.
- Review noisy alerts monthly; tune or remove anything that didn't need a human.

⬅️ [04 · Dynatrace + OTLP](../04-dynatrace/) · 🏠 [Home](../README.md)
