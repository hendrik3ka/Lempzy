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

# Installing IONCUBE
install_ioncube() {
     echo "${grn}Installing IONCUBE ...${end}"
     echo ""
     sleep 3
 
     if ! command -v php >/dev/null 2>&1; then
          echo "${yel}PHP CLI not found. Attempting to install php-cli and php-common...${end}"
          if command -v dnf >/dev/null 2>&1; then
               dnf install -y php-cli php-common >/dev/null 2>&1 || true
          elif command -v yum >/dev/null 2>&1; then
               yum install -y php-cli php-common >/dev/null 2>&1 || true
          fi
          if ! command -v php >/dev/null 2>&1; then
               echo "${red}Error: PHP CLI is not installed. Please install PHP before running Ioncube.${end}"
               return 1
          fi
     fi

     # PHP Modules folder
     MODULES="$(php -r 'echo ini_get("extension_dir");')"
     [ -d "$MODULES" ] || mkdir -p "$MODULES"

     # PHP Version
     PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

     # Download ioncube
     ARCH="$(uname -m 2>/dev/null || echo "")"
     if [ "$ARCH" = "aarch64" ]; then
          PKG="ioncube_loaders_lin_aarch64.zip"
          URL="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.zip"
          if ! command -v unzip >/dev/null 2>&1; then
               if command -v dnf >/dev/null 2>&1; then
                    dnf install -y unzip >/dev/null 2>&1 || true
               elif command -v yum >/dev/null 2>&1; then
                    yum install -y unzip >/dev/null 2>&1 || true
               fi
          fi
          wget -O "$PKG" "$URL"
          unzip -o "$PKG"
          rm -f "$PKG"
     else
          PKG="ioncube_loaders_lin_x86-64.tar.gz"
          URL="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
          wget "$URL"
          tar -xvzf "$PKG"
          rm -f "$PKG"
     fi
 
     LOADER=""
     if [ -f "ioncube/ioncube_loader_lin_${PHP_VERSION}.so" ]; then
          LOADER="ioncube/ioncube_loader_lin_${PHP_VERSION}.so"
     else
          echo "${red}Error: ionCube loader for PHP ${PHP_VERSION} not found in the archive.${end}"
          echo "${yel}ionCube may not yet support this PHP minor version. Please use a supported PHP version or obtain the matching loader.${end}"
          rm -rf ioncube
          return 1
     fi

      cp "$LOADER" "$MODULES/"
      if [ ! -f "$MODULES/ioncube_loader_lin_${PHP_VERSION}.so" ]; then
           echo "${red}Error: Failed to place loader at $MODULES/ioncube_loader_lin_${PHP_VERSION}.so${end}"
           ls -l "$MODULES" || true
           rm -rf ioncube
           return 1
      fi

     mkdir -p /etc/php.d
     echo "zend_extension=$MODULES/ioncube_loader_lin_${PHP_VERSION}.so" >/etc/php.d/00-ioncube.ini
 
     rm -rf ioncube
 
     ACTUAL_PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || true)"
     FPM_SERVICE=""
     if systemctl list-unit-files | grep -q "php${ACTUAL_PHP_VERSION}-fpm.service"; then
          FPM_SERVICE="php${ACTUAL_PHP_VERSION}-fpm"
     elif systemctl list-units | grep -q "php-fpm.service"; then
          FPM_SERVICE="php-fpm"
     else
          CAND="$(systemctl list-unit-files | awk '/php[0-9]+\.[0-9]+-fpm\.service/{print $1}' | head -n1)"
          if [ -n "$CAND" ]; then
               FPM_SERVICE="${CAND%.service}"
          fi
     fi
     if [ -n "$FPM_SERVICE" ]; then
          systemctl enable "$FPM_SERVICE" >/dev/null 2>&1 || true
          systemctl restart "$FPM_SERVICE" || true
     fi
     systemctl restart nginx || true

     echo ""
     sleep 1
}

# Run
install_ioncube
