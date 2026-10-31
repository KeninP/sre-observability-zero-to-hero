#!/usr/bin/env bash
# Read-only first look at a namespace during an incident.
# Usage: ./k8s-triage.sh <namespace>
set -euo pipefail

ns="${1:?usage: $0 <namespace>}"

echo "== Pods not Running/Completed =="
kubectl get pods -n "$ns" --no-headers | awk '$3 != "Running" && $3 != "Completed"' || true

echo; echo "== Restart counts (top 10) =="
kubectl get pods -n "$ns" \
  -o custom-columns='POD:.metadata.name,RESTARTS:.status.containerStatuses[*].restartCount,LAST_REASON:.status.containerStatuses[*].lastState.terminated.reason' \
  --sort-by='.status.containerStatuses[0].restartCount' | tail -n 10

echo; echo "== Warning events (last 20) =="
kubectl get events -n "$ns" --field-selector type=Warning --sort-by=.lastTimestamp | tail -n 20

echo; echo "== Resource usage =="
kubectl top pods -n "$ns" 2>/dev/null || echo "metrics-server not available"

echo; echo "== Rollout status =="
for d in $(kubectl get deploy -n "$ns" -o name); do
  kubectl rollout status "$d" -n "$ns" --timeout=5s || true
done
