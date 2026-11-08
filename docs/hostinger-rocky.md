# Hostinger Rocky Linux deployment

This runbook deploys the stack to a Hostinger KVM VPS running Rocky Linux 9.
The examples use the JSO-364 demo address and sslip.io hostnames:

- `gateway.189.72.147.38.sslip.io`
- `admin.189.72.147.38.sslip.io`

## 1. Access and network firewall

Install an SSH public key in Hostinger before connecting. Do not place the
Hostinger password in a shell command, file, log, or repository. Verify the
server is Rocky Linux 9 before continuing.

In Hostinger's network firewall, allow inbound TCP 22, 80, and 443 only. Do
not add rules for PostgreSQL 5432 or Kong 8000/8001. Apply the firewall without
removing the active SSH rule.

## 2. Bootstrap Rocky Linux

Copy the repository to the server, then run:

```bash
cd /root/apigw
./scripts/bootstrap-rocky.sh
reboot
```

The script installs Docker CE and the Compose plugin from Docker's RHEL
repository, enables firewalld with only SSH/HTTP/HTTPS in the public zone, and
configures both host SELinux enforcement and Docker SELinux labeling. Reconnect
after the SELinux relabel and verify `getenforce` prints `Enforcing` and
`docker info --format '{{json .SecurityOptions}}'` includes `name=selinux`.

## 3. Generate secrets and deploy

Generate the environment on the server so secrets do not cross an extra host:

```bash
cd /root/apigw
./scripts/generate-env.sh \
  gateway.189.72.147.38.sslip.io \
  admin.189.72.147.38.sslip.io \
  zebrasoftwareservices@gmail.com
./scripts/deploy.sh
```

The generated `.env` is ignored by Git and mode 600. Keep
`KONG_ADMIN_TOKEN` server-side only; never copy it to a `NEXT_PUBLIC_*`
variable or browser code.

## 4. Verify and back up

```bash
docker compose ps
./scripts/smoke.sh
BACKUP_DIR=/root/apigw-backups ./scripts/backup.sh
```

Verify HTTPS certificates for both hostnames, confirm unauthenticated Admin
requests return 404, and test 5432/8000/8001 from an external machine to
ensure they are unreachable. Run `docker compose restart`, wait for healthy
services, and repeat the smoke test. Copy the resulting ignored backup to
`/root/apigw-backups` is outside the Git checkout. Copy the resulting mode-600
dump off the VPS as part of routine operations, and record its exact protected
location in the deployment log.

## API Portal values

```dotenv
KONG_ADMIN_URL=https://admin.189.72.147.38.sslip.io
KONG_PROXY_INTERNAL_URL=https://gateway.189.72.147.38.sslip.io
KONG_PROXY_PUBLIC_URL=https://gateway.189.72.147.38.sslip.io
```

Store the matching `KONG_ADMIN_TOKEN` only in the portal server's secret
store. It must not be exposed to the frontend.
