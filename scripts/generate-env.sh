#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$repo_dir/.env"

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <gateway-domain> <admin-domain> <acme-email>" >&2
  exit 2
fi

if [[ -e "$env_file" ]]; then
  echo "Refusing to overwrite $env_file" >&2
  exit 1
fi

umask 077
gateway_domain="$1"
admin_domain="$2"
acme_email="$3"
postgres_password="$(openssl rand -hex 32)"
kong_admin_token="$(openssl rand -hex 32)"

sed \
  -e "s|^GATEWAY_DOMAIN=.*|GATEWAY_DOMAIN=$gateway_domain|" \
  -e "s|^ADMIN_DOMAIN=.*|ADMIN_DOMAIN=$admin_domain|" \
  -e "s|^ACME_EMAIL=.*|ACME_EMAIL=$acme_email|" \
  -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$postgres_password|" \
  -e "s|^KONG_ADMIN_TOKEN=.*|KONG_ADMIN_TOKEN=$kong_admin_token|" \
  "$repo_dir/.env.example" > "$env_file"

chmod 600 "$env_file"
echo "Created $env_file"
echo "Ensure both DNS names resolve to the VM before running ./scripts/deploy.sh"
