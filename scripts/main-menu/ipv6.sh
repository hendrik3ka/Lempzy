#!/usr/bin/env bash

set -Eeuo pipefail

# Colours
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
cyn=$'\e[1;36m'
end=$'\e[0m'

# Ensure running as root
if [[ "$(id -u)" -ne 0 ]]; then
  echo "${red}Please run this script as root${end}"
  exit 1
fi

info() { echo "[INFO] $*"; }
ok() { echo "${grn}[OK]${end} $*"; }
warn() { echo "${yel}[WARN]${end} $*"; }
err() { echo "${red}[ERROR]${end} $*"; }

command -v ip >/dev/null 2>&1 || { err "'ip' command not found"; exit 1; }

has_global_ipv6() {
  # Returns 0 if any global IPv6 address is present on any interface
  # Excludes link-local (fe80::/10). ULAs (fc00::/7) may appear as scope global;
  # we still treat presence of any global-scope IPv6 as 'available' for Nginx config.
  ip -6 addr show scope global 2>/dev/null | awk '/inet6/{print $2}' | grep -vq '^fe80' \
    && return 0 || return 1
}

nginx_installed() { command -v nginx >/dev/null 2>&1; }

nginx_has_ipv6_listen() {
  # Check sites for any IPv6 listen directive
  grep -R -E "listen\s*\[::\]" /etc/nginx/sites-available /etc/nginx/sites-enabled 2>/dev/null | head -n1 | grep -q .
}

# -----------------------------
# UFW (Firewall) helpers
# -----------------------------
ufw_installed() { command -v ufw >/dev/null 2>&1; }

ufw_active() {
  # Returns 0 if UFW Status: active
  ufw status 2>/dev/null | grep -q "Status: active"
}

ensure_ufw_ipv6_enabled() {
  local conf="/etc/ufw/ufw.conf"
  if [[ ! -f "$conf" ]]; then
    warn "UFW config not found: $conf"
    return 0
  fi
  if grep -q '^IPV6=yes' "$conf"; then
    ok "UFW IPV6 already enabled in $conf"
  else
    if grep -q '^IPV6=' "$conf"; then
      sed -i 's/^IPV6=.*/IPV6=yes/' "$conf"
    else
      echo 'IPV6=yes' >>"$conf"
    fi
    ok "Enabled IPv6 in UFW config"
    # Reload UFW to apply config; if reload fails, toggle enable
    if ! ufw reload >/dev/null 2>&1; then
      yes | ufw disable >/dev/null 2>&1 || true
      yes | ufw enable >/dev/null 2>&1 || true
    fi
  fi
}

ensure_ufw_http_https_allowed() {
  # Allow 80/tcp and 443/tcp if not already present
  if ! ufw status | grep -qE '^80/tcp\s+ALLOW'; then
    ufw allow 80/tcp >/dev/null 2>&1 || warn "Failed to allow 80/tcp"
  fi
  if ! ufw status | grep -qE '^443/tcp\s+ALLOW'; then
    ufw allow 443/tcp >/dev/null 2>&1 || warn "Failed to allow 443/tcp"
  fi
  ok "Verified UFW allows HTTP/HTTPS (applies to IPv4 & IPv6 when IPV6=yes)"
}

ensure_ipv6_listen_in_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  # Add IPv6 listeners if missing
  grep -qE "^\s*listen\s*\[::\]:80;" "$f" || sed -i '/^\s*listen\s*80;\s*$/a \  listen [::]:80;' "$f"
  grep -qE "^\s*listen\s*\[::\]:443\s*ssl\s*http2;" "$f" || sed -i '/^\s*listen\s*443\s*ssl\s*http2;\s*$/a \  listen [::]:443 ssl http2;' "$f"
}

configure_nginx_ipv6() {
  if ! nginx_installed; then
    err "Nginx is not installed or not in PATH"
    return 1
  fi

  info "Configuring Nginx to listen on IPv6..."

  # Update Lempzy vhost templates for future sites
  local templates=(
    "/root/Lempzy/scripts/vhost-nocache"
    "/root/Lempzy/scripts/vhost-fastcgi"
    "/root/Lempzy/scripts/vhost-nocache-invoiceninja"
  )
  for t in "${templates[@]}"; do
    if [[ -f "$t" ]]; then
      ensure_ipv6_listen_in_file "$t"
      ok "Updated template: $t"
    else
      warn "Template not found: $t"
    fi
  done

  # Update existing site configs
  for f in /etc/nginx/sites-available/*; do
    [[ -f "$f" ]] || continue
    ensure_ipv6_listen_in_file "$f"
  done

  if nginx -t; then
    systemctl reload nginx || true
    ok "Nginx reloaded with IPv6 listeners"
  else
    err "nginx -t failed; please review your configs"
    return 1
  fi
}

clear
echo "########################### SERVER CONFIGURED BY MIGUEL EMMARA ###########################"
echo "                                   ${grn}IPv6 CONFIGURATION${end}"
echo ""
echo "${cyn}Reminder:${end} If you use Cloudflare (DNS-only), add an AAAA record pointing to your server’s global IPv6 address."
echo "Without an AAAA record, IPv6 clients will not reach your site via IPv6."
echo ""

if ! has_global_ipv6; then
  warn "No global IPv6 address detected on this server."
  echo "${yel}Action required:${end} Obtain an IPv6 address/prefix from your cloud provider and configure it on the server (Netplan/ifupdown)."
  echo "Once IPv6 is configured, re-run this menu to set up Nginx."
  echo "If you use Cloudflare (DNS-only), don’t forget to add an AAAA record with your server’s IPv6 address."
  exit 0
fi

ok "Global IPv6 detected."

if nginx_has_ipv6_listen; then
  ok "Nginx already has IPv6 listen directives. No changes needed."
else
  configure_nginx_ipv6 || exit 1
fi

# If UFW is installed and active, ensure IPv6 enabled and HTTP/HTTPS allowed
if ufw_installed; then
  if ufw_active; then
    info "UFW is active; verifying IPv6 and web ports..."
    ensure_ufw_ipv6_enabled
    ensure_ufw_http_https_allowed
  else
    warn "UFW installed but not active; skipping firewall changes"
  fi
else
  warn "UFW not installed; skipping firewall checks"
fi

echo ""
echo "${grn}IPv6 check and configuration completed.${end}"
echo ""
echo "${cyn}Reminder:${end} If you use Cloudflare (DNS-only), add an AAAA record with your server’s global IPv6 address."
echo "Update DNS so IPv6 resolves correctly for your domain."