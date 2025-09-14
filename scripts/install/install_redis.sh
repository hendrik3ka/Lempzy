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
    
    echo ""
    echo "${grn}Redis Server installed and configured successfully${end}"
    echo "${yel}Redis is listening on 127.0.0.1:6379${end}"
    echo ""
    sleep 1
}

# Run the installation
install_redis