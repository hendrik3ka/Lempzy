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
     
    OS_VER="$(. /etc/os-release; echo "${VERSION_ID}")"
    MAJOR="${OS_VER%%.*}"
    if command -v dnf >/dev/null 2>&1; then
        if ! dnf list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
            dnf install -y "oracle-epel-release-el${MAJOR}"
        fi
        dnf install -y redis
    else
        if ! yum list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
            yum install -y "oracle-epel-release-el${MAJOR}"
        fi
        yum install -y redis
    fi
    
    # Configure Redis
    echo "${grn}Configuring Redis...${end}"
    
    # Backup original config
    cp /etc/redis/redis.conf /etc/redis/redis.conf.backup
    
    # Configure Redis for production use
    sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf
    sed -i 's/^# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
    sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
    
    # Enable and start Redis service
    if systemctl list-unit-files | grep -q "^redis\.service"; then
        systemctl enable redis
        systemctl restart redis
    else
        systemctl enable redis-server 2>/dev/null || true
        systemctl restart redis-server 2>/dev/null || true
    fi
    
    # Test Redis installation
    echo "${grn}Testing Redis installation...${end}"
    if redis-cli ping | grep -q "PONG"; then
        echo "${grn}Redis is running successfully!${end}"
    else
        echo "${red}Redis installation failed or service is not running${end}"
        return 1
    fi
    
    # PHP Redis extension installation is handled separately by scripts/install/install_php_redis.sh

    echo ""
    echo "${grn}Redis Server installed and configured successfully${end}"
    echo "${yel}Redis is listening on 127.0.0.1:6379${end}"
    echo ""
    sleep 1
}

# Run the installation
install_redis
