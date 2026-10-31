# Runbook: <Alert name>

| | |
|---|---|
| **Service** | <service / namespace> |
| **Severity** | P1 / P2 / P3 |
| **Owner** | <team + escalation contact> |
| **Dashboards** | <link> |
| **Last reviewed** | <date> |

## What this alert means
One or two sentences in user terms. *"Customers can't complete checkout"*, not *"error ratio > 0.05"*.

## Impact check (first 5 minutes)
- [ ] Is it real? Check the dashboard and a synthetic monitor.
- [ ] How many users / which regions / which version?
- [ ] Declare the incident and its priority; open the bridge if P1.

## Diagnose
1. What changed? Deployments, config, feature flags, infra in the last 2 h.
2. `./scripts/k8s-triage.sh <namespace>`
3. Traces: slowest / failing spans in the alert window — which dependency?
4. Logs filtered by `trace_id` from a failing trace.

## Mitigate (restore first, root-cause later)
| Situation | Action |
|---|---|
| Bad deploy | `kubectl rollout undo deploy/<name> -n <ns>` |
| Pods wedged after dependency recovered | `./scripts/restart-unhealthy.sh <ns> <deploy> --apply` |
| Capacity | Scale out / raise limits; check HPA |
| Downstream outage | Fail over, enable degraded mode / feature flag |

## Verify
- [ ] Error rate and latency back inside SLO for 15 min
- [ ] Alert resolved; incident updated with timeline

## Escalate if
<conditions and who to call>
