---
service: beacon-api
tags: [latency, errors, performance]
---
# Runbook: High latency or elevated 5xx

**Symptoms:** alert "Beacon API: 5xx errors", p95 latency above SLO.

## Triage
1. Application Insights > Failures: which operation fails? Which dependency (SQL, Key Vault)?
2. KQL: `requests | where timestamp > ago(30m) | summarize count(), avg(duration), percentile(duration,95) by operation_Name`
3. Did a deployment happen in the last hour? Compare the revision timestamp with the start of the errors.
4. SQL CPU / DTU high? Check the `alert-*-sql-cpu` alert and the query performance insights.
5. Container Apps: replicas count, restarts, CPU/memory (Metrics blade).

## Mitigation
Roll back to the previous revision (`az containerapp revision activate` / traffic split), increase `maxReplicas`, or scale the database up.

## Follow-up
Write a postmortem if user-visible for more than 10 minutes.
