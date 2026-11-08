#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

if [[ ! -f .env ]]; then
  echo "Missing .env. Run ./scripts/generate-env.sh first." >&2
  exit 1
fi

if grep -Eq '^[A-Z_]+=([^#]*example\.com|replace-with-a-random)' .env; then
  echo ".env still contains example values." >&2
  exit 1
fi

docker network inspect portal-edge >/dev/null 2>&1 || docker network create portal-edge >/dev/null
docker compose config --quiet
docker compose pull
docker compose up -d --wait postgres

schema_exists="$(docker compose exec -T postgres psql -U kong -d kong -tAc \
  "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'schema_meta');")"

if [[ "$schema_exists" == "t" ]]; then
  docker compose --profile tools run --rm kong-migrations kong migrations up
  docker compose --profile tools run --rm kong-migrations kong migrations finish
else
  docker compose --profile tools run --rm kong-migrations
fi

docker compose up -d --wait kong caddy
"$repo_dir/scripts/smoke.sh"
