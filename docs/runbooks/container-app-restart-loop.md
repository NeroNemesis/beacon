---
service: beacon-api
tags: [containers, startup, aca]
---
# Runbook: Container App restart loop / revision unhealthy

**Symptoms:** revision shows *Unhealthy* or *Degraded*, replicas restarting, no traffic served.

## Triage
1. `az containerapp logs show -g <rg> -n <app> --type system` : image pull errors? probe failures?
2. *Image pull / UNAUTHORIZED* -> the user-assigned identity lacks **AcrPull** on the registry, or the registry is not configured with that identity.
3. *Probe failed* -> the app is not listening on the target port (8080) or `/health/live` returns non-200.
4. Missing env var / secret -> check that the Key Vault reference resolves (identity has **Key Vault Secrets User**).
5. Check Log Analytics: `ContainerAppConsoleLogs_CL | where TimeGenerated > ago(15m)`.

## Mitigation
Activate the previous healthy revision; fix the configuration in Bicep (not in the portal) and redeploy.
