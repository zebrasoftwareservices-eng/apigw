#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

if [[ ! -f .env ]]; then
  echo "Missing .env." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091 -- .env is generated at runtime and intentionally untracked.
source .env
set +a

curl --fail --silent --show-error http://127.0.0.1:8001/status >/dev/null
curl --fail --silent --show-error \
  --header "Kong-Admin-Token: ${KONG_ADMIN_TOKEN}" \
  "https://${ADMIN_DOMAIN}/status" >/dev/null

unauthenticated_status="$(curl --silent --output /dev/null --write-out '%{http_code}' \
  "https://${ADMIN_DOMAIN}/status")"
if [[ "$unauthenticated_status" != "404" ]]; then
  echo "Expected unauthenticated Admin API request to return 404, got $unauthenticated_status" >&2
  exit 1
fi

proxy_status="$(curl --silent --output /dev/null --write-out '%{http_code}' \
  "https://${GATEWAY_DOMAIN}/")"
if [[ "$proxy_status" != "404" ]]; then
  echo "Expected empty Kong proxy to return 404, got $proxy_status" >&2
  exit 1
fi

echo "Kong proxy and protected Admin API are healthy."
