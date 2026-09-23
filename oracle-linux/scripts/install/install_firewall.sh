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

# Install and configure firewalld
install_firewalld() {
     echo "${grn}Installing firewalld ...${end}"
     echo ""
     sleep 3
     if command -v dnf >/dev/null 2>&1; then
          dnf install -y firewalld
     else
          yum install -y firewalld
     fi
     systemctl enable --now firewalld
     echo ""
     sleep 1
}

allow_services() {
     echo "${grn}Allowing SSH, HTTP and HTTPS ...${end}"
     echo ""
     sleep 3
     firewall-cmd --permanent --add-service=ssh || true
     firewall-cmd --permanent --add-service=http || true
     firewall-cmd --permanent --add-service=https || true
     firewall-cmd --reload || true
     echo ""
     sleep 1
}

install_firewalld
allow_services
