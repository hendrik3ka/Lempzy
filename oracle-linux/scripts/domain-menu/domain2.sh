#!/bin/bash

# Script author: Muhamad Miguel Emmara
# Add domain + Install Wordpress + Create Database

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
domain2=$2
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
domainRegex="^[a-zA-Z0-9]"

# Get PHP Installed Version
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

# Ask the user to add domain name
while true; do
     clear
     clear
     echo "########################### SERVER CONFIGURED BY MIGUEL EMMARA ###########################"
     echo "                         ${grn}ADD DOMAIN + INSTALL WP + CREATE DATABASE${end}"
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
     read -p ${grn}"Please provide domain${end}: " domain
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

# Add Domain to the server
add_domain_nginx() {
     mkdir /var/www/$domain
     chown -R $USER:$USER /var/www/$domain
     nginx -t
     systemctl reload nginx
}

# Global variable to track SSL method used
SSL_METHOD=""

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
                            SSL_METHOD="letsencrypt"
                        else
                            if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$domain/privkey.pem" ]; then
                                echo "${yel}Certificate obtained but Nginx installer failed; proceeding with manual install${end}"
                                SSL_METHOD="letsencrypt"
                            else
                                echo "${yel}Trying standalone Certbot (temporarily stopping Nginx)...${end}"
                                systemctl stop nginx >/dev/null 2>&1 || true
                                if certbot certonly --standalone -d "$domain" -d "www.$domain" --email "$ssl_email" --agree-tos --non-interactive --preferred-challenges http; then
                                    echo "${grn}Let's Encrypt certificate obtained (standalone)${end}"
                                    SSL_METHOD="letsencrypt"
                                else
                                    echo "${red}Let's Encrypt failed. Installing self-signed certificate...${end}"
                                    SSL_METHOD=""
                                    install_openssl_certificate
                                fi
                                systemctl start nginx >/dev/null 2>&1 || true
                            fi
                        fi
                    else
                        if certbot --nginx -d "$domain" --email "$ssl_email" --agree-tos --non-interactive --redirect; then
                            echo "${grn}Let's Encrypt SSL certificate installed successfully!${end}"
                            SSL_METHOD="letsencrypt"
                        else
                            if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$domain/privkey.pem" ]; then
                                echo "${yel}Certificate obtained but Nginx installer failed; proceeding with manual install${end}"
                                SSL_METHOD="letsencrypt"
                            else
                                echo "${yel}Trying standalone Certbot (temporarily stopping Nginx)...${end}"
                                systemctl stop nginx >/dev/null 2>&1 || true
                                if certbot certonly --standalone -d "$domain" --email "$ssl_email" --agree-tos --non-interactive --preferred-challenges http; then
                                    echo "${grn}Let's Encrypt certificate obtained (standalone)${end}"
                                    SSL_METHOD="letsencrypt"
                                else
                                    echo "${red}Let's Encrypt failed. Installing self-signed certificate...${end}"
                                    SSL_METHOD=""
                                    install_openssl_certificate
                                fi
                                systemctl start nginx >/dev/null 2>&1 || true
                            fi
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
     SSL_METHOD="openssl"
     service nginx reload
     echo "${yel}Note: Self-signed certificates will show browser warnings${end}"
}

# Install Wordpress
install_wordpress() {
     wget https://wordpress.org/latest.tar.gz
     tar -xf latest.tar.gz
     rm -f latest.tar.gz
     mv wordpress $domain
     mv $domain /var/www/
     mv /var/www/$domain/wp-config-sample.php /var/www/$domain/wp-config.php
     sed -i "s/database_name_here/database_$domainClear2/g" /var/www/$domain/wp-config.php
     sed -i "s/username_here/user_$domainClear2/g" /var/www/$domain/wp-config.php
     sed -i "s/password_here/$PASS/g" /var/www/$domain/wp-config.php
     sed -i "s/( '/('/g" /var/www/$domain/wp-config.php
     sed -i "s/' )/')/g" /var/www/$domain/wp-config.php
     sed -i "s/table_prefix =/table_prefix  =/g" /var/www/$domain/wp-config.php
}

# Delete themes & plugin from wordpress
delete_default_plugin() {
     rm -rf /var/www/$domain/wp-content/themes/twentynineteen
     rm -rf /var/www/$domain/wp-content/themes/twentyseventeen
     rm -rf /var/www/$domain/wp-content/themes/twentysixteen
     rm -rf /var/www/$domain/wp-content/plugins/akismet
     rm -rf /var/www/$domain/wp-content/plugins/hello.php
}

# Install Common Plugin
install_common_plugin() {
     cd /var/www/$domain/wp-content/plugins
     wget https://downloads.wordpress.org/plugin/all-in-one-wp-migration.zip
     unzip all-in-one-wp-migration.zip
     rm -rf all-in-one-wp-migration.zip
     wget https://downloads.wordpress.org/plugin/classic-editor.zip
     unzip classic-editor.zip
     rm -rf classic-editor.zip
     wget https://downloads.wordpress.org/plugin/really-simple-ssl.zip
     unzip really-simple-ssl.zip
     rm -rf really-simple-ssl.zip
     wget https://downloads.wordpress.org/plugin/all-in-one-seo-pack.zip
     unzip all-in-one-seo-pack.zip
     rm -rf all-in-one-seo-pack.zip
}

# Install Nginx Cache
install_nginx_cache() {
     phpToChange="<?php echo esc_attr( get_option( 'nginx_cache_path' ) ); ?>"
     wget https://downloads.wordpress.org/plugin/nginx-cache.zip
     unzip nginx-cache.zip
     rm -rf nginx-cache.zip
     sed -i "s/<?php echo esc_attr( get_option( 'nginx_cache_path' ) ); ?>/\/etc\/nginx\/mycache\/$domain/g" /var/www/$domain/wp-content/plugins/nginx-cache/includes/settings-page.php
     cd

    chown -R nginx:nginx /var/www/$domain
     if systemctl list-unit-files | grep -q "php$PHP_VERSION-fpm.service"; then
          systemctl restart php$PHP_VERSION-fpm.service
     else
          systemctl restart php-fpm.service
     fi
     systemctl restart nginx

     # Add Cache to the server
     mkdir -p /etc/nginx/mycache/$domain
}

# Add nginx Vhost FastCGI for domain
add_vhost() {
     configName=$domain
     cd $sitesAvailable
     cp /root/Lempzy/scripts/vhost-fastcgi $sitesAvailable$domain
     sed -i "s/domain.com/$domain/g" $sitesAvailable$configName
     sed -i "s/phpX.X/php$PHP_VERSION/g" $sitesAvailable$configName
     sed -i "/http2 on;/d" $sitesAvailable$configName
     
     # Configure SSL certificate paths based on SSL method
     if [ "$SSL_METHOD" = "letsencrypt" ]; then
         # Use Let's Encrypt certificate paths
         sed -i "s|ssl_certificate /etc/ssl/$domain/$domain.crt;|ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;|g" $sitesAvailable$configName
         sed -i "s|ssl_certificate_key /etc/ssl/$domain/$domain.key;|ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;|g" $sitesAvailable$configName
         echo "${grn}Configured nginx to use Let's Encrypt certificates${end}"
     else
         # Use OpenSSL certificate paths (default)
         echo "${grn}Configured nginx to use OpenSSL certificates${end}"
     fi
     
     NGINX_VERSION=$(nginx -v 2>&1 | awk -F'/' '/nginx/{print $2}' | tr -d ' \r\n')
     MAJOR="${NGINX_VERSION%%.*}"
     REST="${NGINX_VERSION#*.}"
     MINOR="${REST%%.*}"
     PATCH="${REST#*.}"
     PATCH="${PATCH%%[^0-9]*}"
     if nginx -V 2>&1 | grep -q -- "--with-http_v2_module"; then
          if [ "${MAJOR:-0}" -gt 1 ] || { [ "${MAJOR:-0}" -eq 1 ] && { [ "${MINOR:-0}" -gt 25 ] || { [ "${MINOR:-0}" -eq 25 ] && [ "${PATCH:-0}" -ge 1 ]; }; }; }; then
               sed -i "/ssl_certificate_key /a \  http2 on;" $sitesAvailable$configName
          else
               sed -i "s/listen 443 ssl;/listen 443 ssl http2;/" $sitesAvailable$configName
               sed -i "s/listen \\[::\\]:443 ssl;/listen [::]:443 ssl http2;/" $sitesAvailable$configName
          fi
     fi
     
     if [ ! -f /etc/ssl/certs/dhparam.pem ]; then
          mkdir -p /etc/ssl/certs
          if command -v openssl >/dev/null 2>&1; then
               openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
          else
               sed -i '/^\s*ssl_dhparam\s\+/d' /etc/nginx/nginx.conf
          fi
     fi
}

# PHP POOL SETTING
setting_php_pool() {
     POOL_DIR=""
     if [ -d "/etc/php/$PHP_VERSION/fpm/pool.d" ]; then
          POOL_DIR="/etc/php/$PHP_VERSION/fpm/pool.d"
     elif [ -d "/etc/php-fpm.d" ]; then
          POOL_DIR="/etc/php-fpm.d"
     else
          mkdir -p "/etc/php/$PHP_VERSION/fpm/pool.d" >/dev/null 2>&1 || true
          POOL_DIR="/etc/php/$PHP_VERSION/fpm/pool.d"
     fi
     cp /root/Lempzy/scripts/phpdotdeb "$POOL_DIR/$domain.conf"
     sed -i "s/domain.com/$domain/g" "$POOL_DIR/$domain.conf"
     sed -i "s/phpX.X/php$PHP_VERSION/g" "$POOL_DIR/$domain.conf"
     echo "" >>"$POOL_DIR/$domain.conf"
     dos2unix "$POOL_DIR/$domain.conf" >/dev/null 2>&1 || true
     if systemctl list-unit-files | grep -q "php$PHP_VERSION-fpm.service"; then
          systemctl reload php$PHP_VERSION-fpm.service
     else
          systemctl reload php-fpm.service
     fi

}

selinux_fix() {
     if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" = "Enforcing" ]; then
          if ! command -v semanage >/dev/null 2>&1; then
               if command -v dnf >/dev/null 2>&1; then
                    dnf install -y policycoreutils-python-utils >/dev/null 2>&1 || dnf install -y policycoreutils-python >/dev/null 2>&1 || true
               elif command -v yum >/dev/null 2>&1; then
                    yum install -y policycoreutils-python >/dev/null 2>&1 || yum install -y policycoreutils-python-utils >/dev/null 2>&1 || true
               fi
          fi
          if command -v semanage >/dev/null 2>&1; then
               semanage fcontext -a -t httpd_sys_content_t "/var/www/$domain(/.*)" >/dev/null 2>&1 || true
               semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/$domain/wp-content(/.*)" >/dev/null 2>&1 || true
          fi
          chcon -R -t httpd_sys_content_t "/var/www/$domain" >/dev/null 2>&1 || true
          chcon -R -t httpd_sys_rw_content_t "/var/www/$domain/wp-content" >/dev/null 2>&1 || true
          restorecon -Rv "/var/www/$domain" >/dev/null 2>&1 || true
          if [ -S "/run/php-fpm/$domain-fpm.sock" ]; then
               chcon -t httpd_var_run_t "/run/php-fpm/$domain-fpm.sock" >/dev/null 2>&1 || true
               restorecon -v "/run/php-fpm/$domain-fpm.sock" >/dev/null 2>&1 || true
          fi
     fi
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
     if systemctl list-unit-files | grep -q "php$PHP_VERSION-fpm.service"; then
          systemctl restart php$PHP_VERSION-fpm.service
     else
          systemctl restart php-fpm.service
     fi
}

# Run
create_database
add_domain_nginx
install_ssl
install_wordpress
delete_default_plugin
install_common_plugin
install_nginx_cache
add_vhost
setting_php_pool
selinux_fix
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

echo "Complete! Your new $domain domain has been added! Below is your database credentials..."
echo "PLEASE SAVE BELOW INFORMATION."
echo "Database:   database_$domainClear2"
echo "Username:   user_$domainClear2"
echo "Password:   $PASS"
echo ""
