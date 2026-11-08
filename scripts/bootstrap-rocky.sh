#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root or with sudo." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot identify this operating system." >&2
  exit 1
fi

# shellcheck disable=SC1091 -- this standard runtime file is verified above.
source /etc/os-release
if [[ "${ID:-}" != "rocky" || "${VERSION_ID%%.*}" != "9" ]]; then
  echo "This bootstrap script supports Rocky Linux 9 only." >&2
  exit 1
fi

dnf install -y ca-certificates curl dnf-plugins-core firewalld git openssl \
  policycoreutils selinux-policy-targeted
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf install -y containerd.io container-selinux docker-buildx-plugin \
  docker-ce docker-ce-cli docker-compose-plugin

install -m 0755 -d /etc/docker
if [[ -e /etc/docker/daemon.json ]]; then
  if ! grep -Eq '"selinux-enabled"[[:space:]]*:[[:space:]]*true' /etc/docker/daemon.json; then
    echo "/etc/docker/daemon.json exists without selinux-enabled=true; merge that setting manually." >&2
    exit 1
  fi
else
  install -m 0644 /dev/null /etc/docker/daemon.json
  printf '%s\n' '{' '  "selinux-enabled": true' '}' > /etc/docker/daemon.json
fi

systemctl enable --now docker
systemctl enable --now firewalld

# Start from a deny-by-default public zone and expose only the required ports.
firewall-cmd --permanent --zone=public --set-target=DROP
for service in $(firewall-cmd --permanent --zone=public --list-services); do
  firewall-cmd --permanent --zone=public --remove-service="$service"
done
for port in $(firewall-cmd --permanent --zone=public --list-ports); do
  firewall-cmd --permanent --zone=public --remove-port="$port"
done
for service in ssh http https; do
  firewall-cmd --permanent --zone=public --add-service="$service"
done
firewall-cmd --reload

# Rocky images can ship with policy disabled in /etc/selinux/config. Enabling
# it requires a reboot; autorelabel prepares existing files for enforcement.
selinux_reboot_required=false
if ! grep -q '^SELINUX=enforcing$' /etc/selinux/config || [[ "$(getenforce)" != "Enforcing" ]]; then
  sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
  grubby --update-kernel ALL --remove-args='selinux=0 enforcing=0'
  touch /.autorelabel
  selinux_reboot_required=true
fi

login_user="${SUDO_USER:-}"
if [[ -n "$login_user" && "$login_user" != "root" ]] && id "$login_user" >/dev/null 2>&1; then
  usermod -aG docker "$login_user"
fi

if [[ "$selinux_reboot_required" == true ]]; then
  echo "Docker and firewalld are configured. Reboot now to activate enforcing SELinux."
else
  echo "Docker, firewalld, and enforcing SELinux are configured."
fi
