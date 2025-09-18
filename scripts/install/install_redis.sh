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

# Install Redis
install_redis() {
    echo "${grn}Installing Redis Server...${end}"
    echo ""
    sleep 3
    
    # Update package list
    apt update
    
    # Install Redis server
    apt install redis-server -y
    
    # Configure Redis
    echo "${grn}Configuring Redis...${end}"
    
    # Backup original config
    cp /etc/redis/redis.conf /etc/redis/redis.conf.backup
    
    # Configure Redis for production use
    sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf
    sed -i 's/^# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
    sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
    
    # Enable and start Redis service
    systemctl enable redis-server
    systemctl restart redis-server
    
    # Test Redis installation
    echo "${grn}Testing Redis installation...${end}"
    if redis-cli ping | grep -q "PONG"; then
        echo "${grn}Redis is running successfully!${end}"
    else
        echo "${red}Redis installation failed or service is not running${end}"
        return 1
    fi
    
    # Install PHP Redis extension
    echo "${grn}Installing PHP extension for Redis...${end}"

    # Detect installed PHP version (major.minor) if PHP is available
    ACTUAL_PHP_VERSION=""
    if command -v php >/dev/null 2>&1; then
        ACTUAL_PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || true)"
    fi

    # Try generic php-redis package first; if not available, try version-specific package
    if apt install -y php-redis; then
        :
    elif [ -n "$ACTUAL_PHP_VERSION" ]; then
        apt install -y "php${ACTUAL_PHP_VERSION}-redis" || true
    fi

    # Enable the redis extension for all SAPI if phpenmod is available
    if command -v phpenmod >/dev/null 2>&1; then
        phpenmod -v ALL redis 2>/dev/null || phpenmod redis 2>/dev/null || true
    fi

    # Restart PHP-FPM (if present) to load the redis extension
    FPM_SERVICE=""
    if [ -n "$ACTUAL_PHP_VERSION" ] && systemctl list-unit-files | grep -q "php${ACTUAL_PHP_VERSION}-fpm.service"; then
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
    if command -v php >/dev/null 2>&1 && php -m | grep -qi "^redis$\|^redis "; then
        echo "${grn}PHP Redis extension installed and enabled successfully${end}"
    else
        echo "${yel}PHP Redis extension may not be installed or enabled. Ensure the appropriate package exists for your PHP version.${end}"
    fi
    
    echo ""
    echo "${grn}Redis Server installed and configured successfully${end}"
    echo "${yel}Redis is listening on 127.0.0.1:6379${end}"
    echo ""
    sleep 1
}

# Run the installation
install_redis