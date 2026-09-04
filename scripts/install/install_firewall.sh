#!/bin/bash

set -e

# Colours
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

# Installing UFW Firewall
install_ufw_firewall() {
     echo "${grn}Installing UFW Firewall ...${end}"
     echo ""
     sleep 3
     DEBIAN_FRONTEND=noninteractive apt-get install -y ufw
     echo ""
     sleep 1
}

# Allow SSH through UFW — auto-detect the ACTUAL listening port(s) of sshd
# to prevent locking the operator out when SSH runs on a non-standard port
# (e.g. port 1992) or when sshd_config has been customized before Lempzy runs.
allow_openssh_ufw() {
     echo "${grn}Allowing SSH through UFW ...${end}"
     echo ""

     # 1) Collect every port sshd is currently listening on
     local ssh_ports
     ssh_ports=$(ss -tlnp 2>/dev/null | awk '/sshd/ {print $4}' | grep -oE '[0-9]+$' | sort -un)

     # 2) Add ports declared in sshd_config (Port directives), in case sshd
     #    was restarted with a new port but the socket list lags behind
     local config_ports
     if [ -f /etc/ssh/sshd_config ]; then
          config_ports=$(grep -E '^\s*Port\s+[0-9]+' /etc/ssh/sshd_config | awk '{print $2}' | sort -un)
     fi

     # 3) Merge both lists; fall back to 22 if detection found nothing
     local all_ports
     all_ports=$(printf '%s\n%s\n' "$ssh_ports" "$config_ports" | grep -E '^[0-9]+$' | sort -un)
     if [ -z "$all_ports" ]; then
          echo "${yel}Could not detect sshd ports; defaulting to 22${end}"
          all_ports="22"
     fi

     local has_port_22=false
     for port in $all_ports; do
          echo "  Allowing SSH on port ${blu}$port/tcp${end}"
          sudo ufw allow "$port/tcp"
          [ "$port" = "22" ] && has_port_22=true
     done

     # Safety net: if sshd appears to run on 22 per UFW's own OpenSSH profile,
     # allow the application profile too (covers /etc/ufw/applications.d)
     if $has_port_22; then
          sudo ufw allow OpenSSH 2>/dev/null || true
     fi

     # Refuse to enable the firewall if we somehow found no SSH port at all
     if [ -z "$all_ports" ]; then
          echo "${red}No SSH port allowed — aborting UFW enable to avoid lockout${end}"
          exit 1
     fi
     echo ""
     sleep 1
}

# Enabling UFW
enabling_ufw() {
     echo "${grn}Enabling UFW ...${end}"
     echo ""
     sleep 3
     yes | sudo ufw enable
     echo ""
     sleep 1
}

# Run
install_ufw_firewall
allow_openssh_ufw
enabling_ufw
