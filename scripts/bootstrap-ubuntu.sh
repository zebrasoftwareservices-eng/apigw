#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot identify this operating system." >&2
  exit 1
fi

# shellcheck disable=SC1091 -- this standard runtime file is verified above.
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "This bootstrap script supports Ubuntu only." >&2
  exit 1
fi

install -m 0755 -d /etc/apt/keyrings
apt-get update
apt-get install -y ca-certificates curl git gnupg openssl ufw

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

architecture="$(dpkg --print-architecture)"
printf '%s\n' \
  "deb [arch=${architecture} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

login_user="${SUDO_USER:-ubuntu}"
if id "$login_user" >/dev/null 2>&1; then
  usermod -aG docker "$login_user"
fi

ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "Docker is installed. Log out and back in so the docker group membership takes effect."
