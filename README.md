# apigw

Independent Kong Gateway infrastructure for the API Developer Portal demo.
It supports Rocky Linux 9 on Hostinger and Ubuntu 24.04 on Oracle Cloud, on
both AMD64 and ARM64 hosts.

The stack contains:

- Kong Gateway OSS 3.9 with a PostgreSQL datastore
- Caddy for automatic HTTPS
- a token-protected remote Admin API for the portal server
- an HTTPS reverse proxy for the API Portal control plane
- Terraform for optional Oracle Cloud networking and compute
- bootstrap, deployment, smoke-test, and backup scripts

## Architecture

```text
API clients ──HTTPS──> Caddy ──> Kong proxy ──> upstream APIs

Portal server ──HTTPS + Kong-Admin-Token──> Caddy ──> Kong Admin API

Vercel portal ──HTTPS──> Caddy ──private Docker network──> Portal server

Kong ──private Docker network──> PostgreSQL
```

Kong's raw proxy and Admin ports are bound to localhost. PostgreSQL has no host
port. Only Caddy and SSH are public.

## Quick start

1. Point gateway, admin and portal API DNS names at the VM.
2. Bootstrap the matching operating system:

   ```bash
   # Rocky Linux 9 (run as root)
   ./scripts/bootstrap-rocky.sh

   # Ubuntu 24.04
   sudo ./scripts/bootstrap-ubuntu.sh
   ```

   Reboot Rocky after bootstrap so SELinux starts in enforcing mode. On
   Ubuntu, log out and back in for Docker group membership.

3. Log out and back in, then generate secrets and deploy:

   ```bash
   ./scripts/generate-env.sh \
     gateway.example.com \
     admin.gateway.example.com \
     portal-api.gateway.example.com \
     zebrasoftwareservices@gmail.com
   ./scripts/deploy.sh
   ```

4. Configure the API Portal using [docs/api-portal.md](docs/api-portal.md).

For Hostinger, follow [docs/hostinger-rocky.md](docs/hostinger-rocky.md).
For a new Oracle account, follow [docs/oracle-cloud.md](docs/oracle-cloud.md). Read
[docs/security.md](docs/security.md) before exposing the service.

## Operations

```bash
make status
make logs
make smoke
make backup
```

Backups are written to the ignored `backups/` directory. Copy them off the VM;
a backup stored only on the VM does not protect against VM or volume loss.

## Updating Kong

1. Read the Kong upgrade and breaking-change notes.
2. Run `make backup` and copy the backup off the VM.
3. Change `KONG_IMAGE` in `.env` to a pinned version.
4. Run `./scripts/deploy.sh`.

The deploy script detects an initialized database and runs `migrations up` and
`migrations finish` before recreating Kong.

The Caddy service expects an external Docker network named `portal-edge`;
`scripts/deploy.sh` creates it idempotently before Compose starts.

## Local validation

```bash
./scripts/validate.sh
```

The deployment smoke test requires public DNS and valid TLS certificates, so it
runs only from `deploy.sh`, not from CI.

## License

Apache License 2.0. See [LICENSE](LICENSE).
