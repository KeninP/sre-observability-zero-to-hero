#!/usr/bin/env bash
# Rolling restart of a Deployment whose pods are stuck (CrashLoopBackOff after a fixed dependency, wedged state).
# Prefers `rollout restart` (zero downtime) over scaling to 0. Dry-run by default.
# Usage: ./restart-unhealthy.sh <namespace> <deployment> [--apply]
set -euo pipefail

ns="${1:?usage: $0 <namespace> <deployment> [--apply]}"
deploy="${2:?usage: $0 <namespace> <deployment> [--apply]}"
apply="${3:-}"

echo "Current state of $ns/$deploy:"
kubectl get deploy "$deploy" -n "$ns"
kubectl get pods -n "$ns" -l "$(kubectl get deploy "$deploy" -n "$ns" -o jsonpath='{.spec.selector.matchLabels}' \
  | tr -d '{}"' | sed 's/:/=/g')"

if [[ "$apply" != "--apply" ]]; then
  echo; echo "Dry run. Re-run with --apply to execute: kubectl rollout restart deploy/$deploy -n $ns"
  exit 0
fi

kubectl annotate deploy "$deploy" -n "$ns" --overwrite \
  "incident.sre/last-restart=$(date -u +%Y-%m-%dT%H:%M:%SZ) by ${USER:-pipeline}"
kubectl rollout restart deploy "$deploy" -n "$ns"
kubectl rollout status deploy "$deploy" -n "$ns" --timeout=5m
