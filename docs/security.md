# Security model

## Public surfaces

Oracle's network security list and Ubuntu's firewall expose only:

- TCP 22 for SSH
- TCP 80 for ACME redirects and certificate issuance
- TCP 443 for HTTPS

Kong ports 8000 and 8001 bind to `127.0.0.1` on the VM. Caddy is the only
public entry point.

## Admin API

Kong OSS does not provide the Enterprise RBAC protection expected by a public
Admin API. Caddy therefore requires an exact, random `Kong-Admin-Token` header
before proxying a request to Kong. Unauthorized requests receive 404.

This is reasonable for a low-traffic demonstration but not the preferred
production boundary. A production installation should put the Admin API on a
private network, VPN, or private load balancer and restrict it to portal server
addresses.

Never:

- put `KONG_ADMIN_TOKEN` in browser code or a `NEXT_PUBLIC_*` variable;
- commit `.env`;
- expose ports 8001, 5432, or the Docker socket;
- log request headers at the Caddy layer;
- reuse the PostgreSQL password as the Admin token.

## Rotation

To rotate the Admin token:

1. Generate a new 32-byte value with `openssl rand -hex 32`.
2. Update `KONG_ADMIN_TOKEN` in the gateway `.env`.
3. Update the portal server secret.
4. Run `docker compose up -d --force-recreate caddy`.
5. Run `./scripts/smoke.sh` from the gateway VM.

There will be a brief period where only one of the two services has the new
value. Schedule rotation during a maintenance window.
