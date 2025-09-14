#!/bin/bash

# Script author: Muhamad Miguel Emmara
# Automatic Let's Encrypt SSL Certificate Generation

set -e

# Colours
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

# Function to check if Let's Encrypt (Certbot) is installed
check_letsencrypt_installed() {
    if command -v certbot >/dev/null 2>&1; then
        return 0  # Certbot is installed
    else
        return 1  # Certbot is not installed
    fi
}

# Function to validate domain format
validate_domain() {
    local domain="$1"
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0  # Valid domain
    else
        return 1  # Invalid domain
    fi
}

# Function to get server's public IPv4 address
get_server_ipv4() {
    # Try multiple methods to get IPv4 address
    local server_ip=""
    
    # Method 1: Try curl with IPv4 only
    server_ip=$(curl -4 -s --connect-timeout 5 ifconfig.me 2>/dev/null)
    if [ -n "$server_ip" ] && [[ $server_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$server_ip"
        return 0
    fi
    
    # Method 2: Try alternative service
    server_ip=$(curl -4 -s --connect-timeout 5 ipv4.icanhazip.com 2>/dev/null)
    if [ -n "$server_ip" ] && [[ $server_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$server_ip"
        return 0
    fi
    
    # Method 3: Try to get from network interface (Ubuntu/Debian)
    server_ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    if [ -n "$server_ip" ] && [[ $server_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$server_ip"
        return 0
    fi
    
    # Method 4: Fallback - get primary interface IP
    server_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "$server_ip" ] && [[ $server_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "$server_ip"
        return 0
    fi
    
    echo "unknown"
    return 1
}

# Function to check if domain is accessible (warning only, non-blocking)
check_domain_accessibility() {
    local domain="$1"
    echo "${yel}Checking if $domain is accessible...${end}"
    
    # Get server's IPv4 address
    local server_ip=$(get_server_ipv4)
    local domain_ip=$(dig +short "$domain" 2>/dev/null | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | head -1)
    
    if [ "$domain_ip" = "$server_ip" ] && [ "$server_ip" != "unknown" ]; then
        echo "${grn}✓ Domain $domain resolves to this server ($server_ip)${end}"
        return 0
    else
        echo "${yel}⚠ Warning: Domain $domain resolves to $domain_ip, but server IP is $server_ip${end}"
        echo "${yel}  Let's Encrypt may fail if domain doesn't point to this server${end}"
        echo "${yel}  Continuing anyway as requested...${end}"
        return 0  # Changed to return 0 (success) to continue process
    fi
}

# Function to generate Let's Encrypt SSL certificate
generate_letsencrypt_ssl() {
    local domain="$1"
    local email="$2"
    
    echo "${grn}Generating Let's Encrypt SSL certificate for $domain...${end}"
    echo ""
    
    # Validate domain format
    if ! validate_domain "$domain"; then
        echo "${red}Error: Invalid domain format: $domain${end}"
        return 1
    fi
    
    # Check domain accessibility (warning only)
    check_domain_accessibility "$domain"
    
    # Generate certificate using certbot with nginx plugin
    if certbot --nginx -d "$domain" --email "$email" --agree-tos --non-interactive --redirect; then
        echo "${grn}SSL certificate generated successfully for $domain!${end}"
        echo "${grn}Certificate will auto-renew via cron job${end}"
        return 0
    else
        echo "${red}Failed to generate SSL certificate for $domain${end}"
        echo "${yel}Common reasons for failure:${end}"
        echo "${yel}- Domain doesn't point to this server${end}"
        echo "${yel}- Port 80/443 not accessible from internet${end}"
        echo "${yel}- Firewall blocking connections${end}"
        echo "${yel}- Domain not properly configured in nginx${end}"
        return 1
    fi
}

# Function to generate SSL with www subdomain
generate_letsencrypt_ssl_with_www() {
    local domain="$1"
    local email="$2"
    
    echo "${grn}Generating Let's Encrypt SSL certificate for $domain and www.$domain...${end}"
    echo ""
    
    # Validate domain format
    if ! validate_domain "$domain"; then
        echo "${red}Error: Invalid domain format: $domain${end}"
        return 1
    fi
    
    # Check domain accessibility (warning only)
    check_domain_accessibility "$domain"
    check_domain_accessibility "www.$domain"
    
    # Generate certificate for both domain and www subdomain
    if certbot --nginx -d "$domain" -d "www.$domain" --email "$email" --agree-tos --non-interactive --redirect; then
        echo "${grn}SSL certificate generated successfully for $domain and www.$domain!${end}"
        echo "${grn}Certificate will auto-renew via cron job${end}"
        return 0
    else
        echo "${red}Failed to generate SSL certificate for $domain and www.$domain${end}"
        echo "${yel}Trying with domain only...${end}"
        generate_letsencrypt_ssl "$domain" "$email"
        return $?
    fi
}

# Main function for interactive SSL generation
interactive_ssl_generation() {
    local domain="$1"
    
    # Check if Let's Encrypt is installed
    if ! check_letsencrypt_installed; then
        echo "${red}Error: Let's Encrypt (Certbot) is not installed!${end}"
        echo "${yel}Please install Let's Encrypt first from the main installation menu${end}"
        return 1
    fi
    
    echo "${grn}=== LET'S ENCRYPT SSL CERTIFICATE GENERATION ===${end}"
    echo ""
    
    # Get domain if not provided
    if [ -z "$domain" ]; then
        read -p "${cyn}Enter your domain name (e.g., example.com): ${end}" domain
    fi
    
    # Get email for Let's Encrypt notifications
    read -p "${cyn}Enter your email address for SSL notifications: ${end}" email
    
    # Validate email format (basic validation)
    if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "${red}Error: Invalid email format${end}"
        return 1
    fi
    
    # Ask if user wants to include www subdomain
    echo ""
    echo "${yel}Do you want to include www.$domain in the certificate?${end}"
    read -p "${cyn}Include www subdomain? (y/n): ${end}" include_www
    
    echo ""
    echo "${yel}Important: Make sure your domain points to this server before proceeding!${end}"
    echo "${yel}Server IP: $(get_server_ipv4)${end}"
    echo ""
    read -p "${cyn}Continue with SSL certificate generation? (y/n): ${end}" confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        if [[ $include_www =~ ^[Yy]$ ]]; then
            generate_letsencrypt_ssl_with_www "$domain" "$email"
        else
            generate_letsencrypt_ssl "$domain" "$email"
        fi
    else
        echo "${yel}SSL certificate generation cancelled${end}"
        return 1
    fi
}

# If script is called directly with domain parameter
if [ $# -gt 0 ]; then
    interactive_ssl_generation "$1"
else
    interactive_ssl_generation
fi