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

# Install Let's Encrypt (Certbot)
install_letsencrypt() {
    echo "${grn}Installing Let's Encrypt (Certbot)...${end}"
    echo ""
    sleep 3
    OS_ID="$(. /etc/os-release; echo "${ID}")"
    OS_VER="$(. /etc/os-release; echo "${VERSION_ID}")"
    MAJOR="${OS_VER%%.*}"
    if command -v dnf >/dev/null 2>&1; then
        if ! dnf list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
            dnf install -y "oracle-epel-release-el${MAJOR}"
        fi
        dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && dnf config-manager --enable ol9_codeready_builder && dnf install -y certbot python3-certbot-nginx
    else
        if ! yum list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
            yum install -y "oracle-epel-release-el${MAJOR}"
        fi
        yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && yum config-manager --enable ol9_codeready_builder && yum install -y certbot python3-certbot-nginx
    fi
    mkdir -p /etc/letsencrypt
    mkdir -p /var/log/letsencrypt
    chmod 755 /etc/letsencrypt
    chmod 755 /var/log/letsencrypt
    echo "${grn}Setting up automatic certificate renewal...${end}"
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    if certbot --version >/dev/null 2>&1; then
        echo "${grn}Let's Encrypt (Certbot) installed successfully!${end}"
        echo "${yel}To obtain SSL certificates, run: certbot --nginx -d yourdomain.com${end}"
        echo "${yel}Automatic renewal is configured via cron job${end}"
    else
        echo "${red}Let's Encrypt installation failed${end}"
        return 1
    fi
    echo ""
    echo "${grn}Let's Encrypt installation completed${end}"
    echo "${yel}Note: You'll need to configure your domain and obtain certificates manually${end}"
    echo "${yel}Example: certbot --nginx -d example.com -d www.example.com${end}"
    echo ""
    sleep 1
}

# Run the installation
install_letsencrypt
