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

# Install PHP Redis extension
install_php_redis() {
     echo "${grn}Installing PHP extension for Redis...${end}"

    OS_VER="$(. /etc/os-release; echo "${VERSION_ID}")"
    MAJOR="${OS_VER%%.*}"
    if command -v dnf >/dev/null 2>&1; then
        if ! dnf list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
            dnf install -y "oracle-epel-release-el${MAJOR}"
        fi
    else
        if ! yum list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
            yum install -y "oracle-epel-release-el${MAJOR}"
        fi
    fi

    # Detect installed PHP version (major.minor) if PHP is available
    ACTUAL_PHP_VERSION=""
    if command -v php >/dev/null 2>&1; then
        ACTUAL_PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || true)"
    fi

    # If PHP is not installed, skip with message
    if [ -z "$ACTUAL_PHP_VERSION" ]; then
        echo "${yel}PHP CLI not detected. Skipping PHP Redis extension installation.${end}"
        return 0
    fi

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y php-pecl-redis || dnf install -y php-redis || true
    else
        yum install -y php-pecl-redis || yum install -y php-redis || true
    fi

    # Restart PHP-FPM (if present) to load the redis extension
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

    # Verify PHP Redis extension installation
    if php -m | grep -qi "^redis$\|^redis "; then
        echo "${grn}PHP Redis extension installed and enabled successfully${end}"
    else
        echo "${yel}PHP Redis extension may not be installed or enabled. Ensure the appropriate package exists for your PHP version.${end}"
    fi
}

# Run the installation
install_php_redis
