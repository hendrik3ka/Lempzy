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

# Install PHP
install_php() {
     if [[ -n "$SELECTED_PHP_VERSION" && "$SELECTED_PHP_VERSION" != "auto" ]]; then
          install_specific_php_version "$SELECTED_PHP_VERSION"
          return
     fi
     OS_ID="$(. /etc/os-release; echo "${ID}")"
     OS_VER="$(. /etc/os-release; echo "${VERSION_ID}")"
     if [[ "$OS_ID" == "ol" || "$OS_ID" == "oraclelinux" ]]; then
          MAJOR="${OS_VER%%.*}"
          if [[ "$MAJOR" -ge 9 ]]; then
               SELECTED_PHP_VERSION="8.3"
          else
               SELECTED_PHP_VERSION="8.2"
          fi
          install_specific_php_version "$SELECTED_PHP_VERSION"
     else
          echo -e "${red}Unsupported OS for this installer${end}"
          exit 1
     fi
}

# Configure PHP FPM
configure_php_fpm() {
     echo "${grn}Configure PHP FPM ...${end}"
     echo ""
     sleep 3
     if [ -f /etc/php.ini ]; then
          sed -i "s/^max_execution_time = .*/max_execution_time = 360/" /etc/php.ini || true
          sed -i "s/^display_errors = .*/display_errors = Off/" /etc/php.ini || true
          sed -i "s/^memory_limit = .*/memory_limit = 512M/" /etc/php.ini || true
          sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php.ini || true
          sed -i "s/^post_max_size = .*/post_max_size = 256M/" /etc/php.ini || true
     fi
     if [ -f /etc/php-fpm.d/www.conf ]; then
          sed -i "s/^user = .*/user = nginx/" /etc/php-fpm.d/www.conf || true
          sed -i "s/^group = .*/group = nginx/" /etc/php-fpm.d/www.conf || true
          sed -i "s/^;*listen.owner = .*/listen.owner = nginx/" /etc/php-fpm.d/www.conf || true
          sed -i "s/^;*listen.group = .*/listen.group = nginx/" /etc/php-fpm.d/www.conf || true
     fi
     systemctl enable php-fpm 2>/dev/null || true
     systemctl restart php-fpm 2>/dev/null || true
     echo ""
     sleep 1
}

# Function to install specific PHP version
install_specific_php_version() {
     local php_version="$1"
     echo "${grn}Installing PHP $php_version...${end}"
     echo ""
     sleep 3
     OS_ID="$(. /etc/os-release; echo "${ID}")"
     OS_VER="$(. /etc/os-release; echo "${VERSION_ID}")"
     if [[ "$OS_ID" != "ol" && "$OS_ID" != "oraclelinux" ]]; then
          echo "${red}Unsupported OS${end}"
          return 1
     fi
     MAJOR="${OS_VER%%.*}"
     if command -v dnf >/dev/null 2>&1; then
          if ! dnf list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
               dnf install -y "oracle-epel-release-el${MAJOR}"
          fi
          dnf install -y "https://rpms.remirepo.net/enterprise/remi-release-${MAJOR}.rpm"
          dnf -y module reset php || true
          case "$php_version" in
               "7.4") dnf -y module enable php:remi-7.4 ;;
               "8.0") dnf -y module enable php:remi-8.0 ;;
               "8.1") dnf -y module enable php:remi-8.1 ;;
               "8.2") dnf -y module enable php:remi-8.2 ;;
               "8.3") dnf -y module enable php:remi-8.3 ;;
               *) echo "${red}Unsupported PHP version: $php_version${end}"; return 1 ;;
          esac
          dnf install -y php-fpm php-cli php-common php-mysqlnd php-gd php-curl php-intl php-zip php-mbstring php-opcache php-soap php-pecl-apcu 2>/dev/null || dnf install -y php-fpm php-cli php-common php-mysqlnd php-gd php-curl php-intl php-zip php-mbstring php-opcache php-soap || true
     else
          yum install -y "oracle-epel-release-el${MAJOR}" || true
          yum install -y "https://rpms.remirepo.net/enterprise/remi-release-${MAJOR}.rpm"
          yum -y module reset php || true
          case "$php_version" in
               "7.4") yum -y module enable php:remi-7.4 ;;
               "8.0") yum -y module enable php:remi-8.0 ;;
               "8.1") yum -y module enable php:remi-8.1 ;;
               "8.2") yum -y module enable php:remi-8.2 ;;
               "8.3") yum -y module enable php:remi-8.3 ;;
               *) echo "${red}Unsupported PHP version: $php_version${end}"; return 1 ;;
          esac
          yum install -y php-fpm php-cli php-common php-mysqlnd php-gd php-curl php-intl php-zip php-mbstring php-opcache php-soap php-pecl-apcu || true
     fi
     systemctl enable --now php-fpm 2>/dev/null || true
     
     ACTUAL_PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "$php_version")"
     
     echo "${grn}Setting PHP $ACTUAL_PHP_VERSION as default...${end}"
     
     FPM_SERVICE=""
     if systemctl list-unit-files | grep -q "^php-fpm\.service"; then
          systemctl enable php-fpm
          systemctl start php-fpm
          FPM_SERVICE="php-fpm"
     else
          CAND="$(systemctl list-unit-files | awk '/php[0-9]+\.[0-9]+-fpm\.service/{print $1}' | head -n1)"
          if [ -n "$CAND" ]; then
               systemctl enable "${CAND%.service}"
               systemctl start "${CAND%.service}"
               FPM_SERVICE="${CAND%.service}"
          else
               echo "${yel}Warning: PHP-FPM service not found${end}"
          fi
     fi
     
     # Verify installation
     if command -v php >/dev/null 2>&1; then
          INSTALLED_VERSION=$(php -v 2>/dev/null | head -1 | grep -o 'PHP [0-9]\.[0-9]' | cut -d' ' -f2 || echo "unknown")
          if [ "$INSTALLED_VERSION" != "unknown" ]; then
               echo "${grn}PHP $INSTALLED_VERSION installed and configured successfully${end}"
               if [ "$INSTALLED_VERSION" != "$php_version" ]; then
                    echo "${yel}Note: Installed PHP $INSTALLED_VERSION instead of requested $php_version${end}"
               fi
          else
               echo "${yel}Warning: PHP version verification failed, but installation completed${end}"
          fi
     else
          if command -v dnf >/dev/null 2>&1; then
               dnf install -y php-cli >/dev/null 2>&1 || true
          elif command -v yum >/dev/null 2>&1; then
               yum install -y php-cli >/dev/null 2>&1 || true
          fi
          if command -v php >/dev/null 2>&1; then
               INSTALLED_VERSION=$(php -v 2>/dev/null | head -1 | grep -o 'PHP [0-9]\.[0-9]' | cut -d' ' -f2 || echo "unknown")
               echo "${grn}PHP $INSTALLED_VERSION installed and configured successfully${end}"
          else
               echo "${red}Error: PHP command not found after installation${end}"
          fi
     fi
     
     echo ""
     sleep 1
}

# Run
install_php
configure_php_fpm
