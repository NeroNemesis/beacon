---
service: beacon-api
tags: [sql, connectivity, identity]
---
# Runbook: API cannot connect to Azure SQL

**Symptoms:** 5xx on /api/*, `/health/ready` failing, logs show `Login failed for user '<token-identified principal>'` or a timeout.

## Triage
1. Is the database paused (serverless auto-pause)? First connection after a pause can take 30–60 s. Retry once.
2. Check the error text:
   - *Login failed for user '<token-identified principal>'* -> the managed identity has no contained user. Run `CREATE USER [id-beacon-dev] FROM EXTERNAL PROVIDER;` then add `db_datareader`/`db_datawriter`.
   - *Client with IP address ... is not allowed* -> public access disabled or firewall rule missing; check the private endpoint path instead.
3. From a VM in the VNet: `nslookup <server>.database.windows.net` must return a **10.x** address. A public IP means the private DNS zone link is broken.
4. Check Azure SQL "Networking" and the private endpoint connection state (must be *Approved*).

## Mitigation
Re-link the private DNS zone to the VNet; re-create the contained user; scale up temporarily if CPU is saturated.

## Escalation
If not resolved in 30 min, page the platform owner.
