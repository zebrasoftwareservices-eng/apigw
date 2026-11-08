#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <ssh-user>@<public-ip>" >&2
  exit 2
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
remote="$1"

ssh "$remote" 'mkdir -p ~/apigw'
rsync -az --delete \
  --exclude .git \
  --exclude .terraform \
  --exclude backups \
  "$repo_dir/" "$remote:~/apigw/"

ssh -t "$remote" 'cd ~/apigw && ./scripts/deploy.sh'
