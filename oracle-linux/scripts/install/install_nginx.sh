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

# Install and start nginx
install_nginx() {
     echo "${grn}Installing NGINX ...${end}"
     echo ""
     sleep 3
     if command -v dnf >/dev/null 2>&1; then
          dnf install -y nginx
     else
          yum install -y nginx
     fi
     systemctl enable --now nginx
     firewall-cmd --permanent --add-service=http || true
     firewall-cmd --permanent --add-service=https || true
     firewall-cmd --reload || true
     echo ""
     sleep 1
}

# Config to make PHP-FPM working with Nginx
configuring_php_fpm_nginx() {
     echo "${grn}Configuring to make PHP-FPM working with Nginx ...${end}"
     echo ""
     sleep 3
     # Get the directory where this script is located
     SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     # Go up one level to get the scripts directory
     SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")"
     
     # Check if nginx.conf exists in the scripts directory
     if [ -f "$SCRIPTS_DIR/nginx.conf" ]; then
          echo "${grn}Found nginx.conf at: $SCRIPTS_DIR/nginx.conf${end}"
          rm -rf /etc/nginx/nginx.conf
          cd /etc/nginx/
          cp "$SCRIPTS_DIR/nginx.conf" nginx.conf
          dos2unix /etc/nginx/nginx.conf
          mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
          cd
          mkdir -p /etc/ssl/certs
          if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
               echo "${grn}Generating Diffie-Hellman parameters (dhparam.pem)...${end}"
               if command -v openssl >/dev/null 2>&1; then
                    openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
               else
                    echo "${yel}OpenSSL not found; removing ssl_dhparam directive to avoid errors${end}"
                    sed -i '/^\s*ssl_dhparam\s\+/d' /etc/nginx/nginx.conf
               fi
          fi
     else
          echo "${red}Error: nginx.conf not found at $SCRIPTS_DIR/nginx.conf${end}"
          echo "${yel}Please ensure the nginx.conf file exists in the scripts directory${end}"
          return 1
     fi
     
     echo ""
     sleep 1
}

# Run
install_nginx
configuring_php_fpm_nginx
