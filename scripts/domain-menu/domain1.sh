#!/bin/bash

# Script author: Muhamad Miguel Emmara
# Add Domian + Create Database

set -e

# Colours
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

# Check if you are root
if [ "$(whoami)" != 'root' ]; then
     echo "You have no permission to run $0 as non-root user. Use sudo"
     exit 1
fi

# Variables
domain=$1
domain2=$3
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
domainRegex="^[a-zA-Z0-9]"

# Get PHP Installed Version
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

# Ask the user to add domain name
while true; do

     clear
     echo "########################### SERVER CONFIGURED BY MIGUEL EMMARA ###########################"
     echo "                                   ${grn}ADD DOMAIN ONLY${end}"
     echo ""
     echo "     __                                    "
     echo "    / /   ___  ____ ___  ____  ____  __  __"
     echo "   / /   / _ \/ __ \`__ \/ __ \/_  / / / / /"
     echo "  / /___/  __/ / / / / / /_/ / / /_/ /_/ /"
     echo " /_____/\___/_/ /_/ /_/ .___/ /___/\__, /"
     echo "                   /_/          /____/_/"
     echo ""
     echo "${grn}Press [CTRL + C] to cancel...${end}"
     echo ""

     read -p ${grn}"Please provide your domain${end}: " domain
     read -p ${grn}"Please type your domain one more time${end}: " domain2
     echo
     [ "$domain" = "$domain2" ] && break
     echo "Domain you provide does not match, please try again!"
     read -p "${grn}Press [Enter] key to continue...${end}" readEnterKey
done

until [[ $domain =~ $domainRegex ]]; do
     echo -n "Enter valid domain: "
     read domain
done

# Check if domain already added
if [ -e $sitesAvailable$domain ]; then
     echo "This domain already exists. Please delete your domain from the main menu options and try again"
     exit
fi

# Check if domain already added var www
if [ -e /var/www/$domain ]; then
     echo "This domain already exists. Please delete your domain from the main menu options and try again"
     exit
fi

# Create Database
create_database() {
     domainClear=${domain//./}
     domainClear2=${domainClear//-/}
     echo "Type the password for your new $domain database [eg, password123_$domainClear2]"
     echo -n "followed by [ENTER]: "
     read PASS
          mysql -uroot <<MYSQL_SCRIPT
          CREATE DATABASE database_$domainClear2;
          CREATE USER 'user_$domainClear2'@'localhost' IDENTIFIED BY '$PASS';
          GRANT ALL PRIVILEGES ON database_$domainClear2.* TO 'user_$domainClear2'@'localhost';
          FLUSH PRIVILEGES;
MYSQL_SCRIPT

}

# Install ssl
install_ssl() {
     echo "${grn}=== SSL CERTIFICATE SETUP ===${end}"
     echo "${yel}Choose your SSL certificate type:${end}"
     echo "${blu}1) Let's Encrypt (Free, Trusted, Auto-renewal)${end}"
     echo "${blu}2) Self-signed OpenSSL (Quick setup, Browser warning)${end}"
     echo ""
     read -p "${cyn}Enter your choice (1-2): ${end}" ssl_choice
     
     case $ssl_choice in
         1)
             # Check if Let's Encrypt is installed
             if command -v certbot >/dev/null 2>&1; then
                 echo "${grn}Setting up Let's Encrypt SSL certificate...${end}"
                 
                 # Get email for Let's Encrypt
                 read -p "${cyn}Enter your email for SSL notifications: ${end}" ssl_email
                 
                 # Validate email format
                 if [[ ! $ssl_email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                     echo "${red}Invalid email format. Using self-signed certificate instead.${end}"
                     install_openssl_certificate
                     return
                 fi
                 
                 # Ask about www subdomain
                 read -p "${cyn}Include www.$domain in certificate? (y/n): ${end}" include_www
                 
                 echo "${yel}Important: Make sure $domain points to this server!${end}"
                  # Get server IPv4 address using multiple methods
                  local server_ip=$(curl -4 -s --connect-timeout 5 ifconfig.me 2>/dev/null)
                  if [ -z "$server_ip" ] || [[ ! $server_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                      server_ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
                  fi
                  if [ -z "$server_ip" ] || [[ ! $server_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                      server_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
                  fi
                  echo "${yel}Server IP: ${server_ip:-unknown}${end}"
                 read -p "${cyn}Continue? (y/n): ${end}" confirm
                 
                 if [[ $confirm =~ ^[Yy]$ ]]; then
                     # Generate Let's Encrypt certificate
                     if [[ $include_www =~ ^[Yy]$ ]]; then
                         if certbot --nginx -d "$domain" -d "www.$domain" --email "$ssl_email" --agree-tos --non-interactive --redirect; then
                             echo "${grn}Let's Encrypt SSL certificate installed successfully!${end}"
                         else
                             echo "${red}Let's Encrypt failed. Installing self-signed certificate...${end}"
                             install_openssl_certificate
                         fi
                     else
                         if certbot --nginx -d "$domain" --email "$ssl_email" --agree-tos --non-interactive --redirect; then
                             echo "${grn}Let's Encrypt SSL certificate installed successfully!${end}"
                         else
                             echo "${red}Let's Encrypt failed. Installing self-signed certificate...${end}"
                             install_openssl_certificate
                         fi
                     fi
                 else
                     echo "${yel}Let's Encrypt cancelled. Installing self-signed certificate...${end}"
                     install_openssl_certificate
                 fi
             else
                 echo "${red}Let's Encrypt (Certbot) is not installed!${end}"
                 echo "${yel}Installing self-signed certificate instead...${end}"
                 install_openssl_certificate
             fi
             ;;
         2)
             install_openssl_certificate
             ;;
         *)
             echo "${red}Invalid choice. Installing self-signed certificate...${end}"
             install_openssl_certificate
             ;;
     esac
}

# Function to install OpenSSL self-signed certificate
install_openssl_certificate() {
     echo "${grn}Installing self-signed SSL certificate...${end}"
     mkdir -p /etc/ssl/$domain/
     cd /etc/ssl/$domain/
     openssl req -new -newkey rsa:2048 -sha256 -nodes -out $domain.csr -keyout $domain.key -subj "/C=US/ST=Rhode Island/L=East Greenwich/O=Fidelity Test/CN=$domain"
     openssl x509 -req -days 36500 -in $domain.csr -signkey $domain.key -out $domain.crt
     service nginx reload
     echo "${yel}Note: Self-signed certificates will show browser warnings${end}"
}

# Add html file to the domain
add_html_file_test() {

     # Add Domain to the server
     mkdir /var/www/$domain
     if ! echo "domain has been added!" >/var/www/$domain/index.html; then
          echo "There is an ERROR create index.html file"
          exit
     else
          echo "index.html has been created successfully"
     fi
     chown -R $USER:$USER /var/www/$domain
     nginx -t
     systemctl reload nginx
     chown -R www-data:www-data /var/www/$domain
     systemctl restart php$PHP_VERSION-fpm.service
     systemctl restart nginx

}

# Add nginx Vhost FastCGI for domain
add_vhost() {
     # Add Cache to the server
     mkdir -p /etc/nginx/mycache/$domain

     configName=$domain
     cd $sitesAvailable
     # Get the directory where this script is located dynamically
     SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     LEMPZY_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
     
     cp "$LEMPZY_ROOT/scripts/vhost-fastcgi" $sitesAvailable$domain
     sed -i "s/domain.com/$domain/g" $sitesAvailable$configName
     sed -i "s/phpX.X/php$PHP_VERSION/g" $sitesAvailable$configName
}

# PHP POOL SETTING
setting_php_pool() {
     # Get the directory where this script is located dynamically
     SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
     LEMPZY_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
     
     cp "$LEMPZY_ROOT/scripts/phpdotdeb" /etc/php/$PHP_VERSION/fpm/pool.d/$domain.conf
     sed -i "s/domain.com/$domain/g" /etc/php/$PHP_VERSION/fpm/pool.d/$domain.conf
     sed -i "s/phpX.X/php$PHP_VERSION/g" /etc/php/$PHP_VERSION/fpm/pool.d/$domain.conf
     echo "" >>/etc/php/$PHP_VERSION/fpm/pool.d/$domain.conf
     dos2unix /etc/php/$PHP_VERSION/fpm/pool.d/$domain.conf >/dev/null 2>&1
     service php$PHP_VERSION-fpm reload

}

# Create Symbolic Links
create_symbolic_links() {
     ln -s $sitesAvailable$configName $sitesEnable$configName
     nginx -t
     systemctl reload nginx
}

# Restart nginx and php-fpm
restart_services() {
     echo "Restart Nginx & PHP-FPM ..."
     echo ""
     sleep 1
     systemctl restart nginx
     systemctl restart php$PHP_VERSION-fpm.service

}

# Run
create_database
install_ssl
add_html_file_test
add_vhost
setting_php_pool
create_symbolic_links
restart_services

# Success Prompt
clear
echo "Script By"
echo ""
echo "     __                                    "
echo "    / /   ___  ____ ___  ____  ____  __  __"
echo "   / /   / _ \/ __ \`__ \/ __ \/_  / / / / /"
echo "  / /___/  __/ / / / / / /_/ / / /_/ /_/ /"
echo " /_____/\___/_/ /_/ /_/ .___/ /___/\__, /"
echo "                   /_/          /____/_/"
echo ""

echo "Complete! Your new $domain domain has been added!"
echo "PLEASE SAVE BELOW INFORMATION."
echo "Database:   database_$domainClear2"
echo "Username:   user_$domainClear2"
echo "Password:   $PASS"
echo ""
