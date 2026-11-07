# apigw

Independent Kong Gateway infrastructure for the API Developer Portal demo.
It targets an Oracle Cloud Always Free Ampere A1 VM and also runs on AMD64.

The stack contains:

- Kong Gateway OSS 3.9 with a PostgreSQL datastore
- Caddy for automatic HTTPS
- a token-protected remote Admin API for the portal server
- Terraform for Oracle Cloud networking and compute
- bootstrap, deployment, smoke-test, and backup scripts

## Architecture

```text
API clients ──HTTPS──> Caddy ──> Kong proxy ──> upstream APIs

Portal server ──HTTPS + Kong-Admin-Token──> Caddy ──> Kong Admin API

Kong ──private Docker network──> PostgreSQL
```

Kong's raw proxy and Admin ports are bound to localhost. PostgreSQL has no host
port. Only Caddy and SSH are public.

## Quick start on an existing Ubuntu VM

1. Point gateway and admin DNS names at the VM.
2. Install Docker:

   ```bash
   sudo ./scripts/bootstrap-ubuntu.sh
   ```

3. Log out and back in, then generate secrets and deploy:

   ```bash
   ./scripts/generate-env.sh \
     gateway.example.com \
     admin.gateway.example.com \
     admin@example.com
   ./scripts/deploy.sh
   ```

4. Configure the API Portal using [docs/api-portal.md](docs/api-portal.md).

For a new Oracle account, follow
[docs/oracle-cloud.md](docs/oracle-cloud.md). Read
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

## Local validation

```bash
./scripts/validate.sh
```

The deployment smoke test requires public DNS and valid TLS certificates, so it
runs only from `deploy.sh`, not from CI.

## License

Apache License 2.0. See [LICENSE](LICENSE).
