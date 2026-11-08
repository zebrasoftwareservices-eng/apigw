#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backup_dir="${BACKUP_DIR:-$repo_dir/backups}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_file="$backup_dir/kong-$timestamp.dump"

mkdir -p "$backup_dir"
umask 077
cd "$repo_dir"
docker compose exec -T postgres pg_dump -U kong -d kong -Fc > "$backup_file"
chmod 600 "$backup_file"
echo "Created $backup_file"
