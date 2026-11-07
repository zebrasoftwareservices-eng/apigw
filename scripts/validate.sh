#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

for script in scripts/*.sh; do
  bash -n "$script"
done

docker compose --env-file .env.example config --quiet

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck scripts/*.sh
fi

if command -v terraform >/dev/null 2>&1; then
  terraform -chdir=infra/terraform fmt -check -recursive
  terraform -chdir=infra/terraform init -backend=false -input=false >/dev/null
  terraform -chdir=infra/terraform validate
fi

echo "Validation passed."
