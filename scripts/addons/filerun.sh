#!/bin/bash

# Script author: Muhamad Miguel Emmara
# Install Filerun

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

# Detect the correct PHP-FPM systemd unit (handles Remi/EPEL and distro naming).
detect_fpm_service() {
    local candidates
    candidates="php$PHP_VERSION-fpm.service php-fpm.service php$PHP_VERSION-fpm php-fpm"
    local c
    for c in $candidates; do
        if systemctl list-unit-files | grep -q "^$c"; then
            echo "$c"
            return 0
        fi
    done
    local found
    found=$(systemctl list-unit-files 2>/dev/null | grep -i 'fpm.*\.service' | awk '{print $1}' | head -n1)
    if [ -n "$found" ]; then
        echo "$found"
        return 0
    fi
    return 1
}

FPM_SERVICE="$(detect_fpm_service)"

fpm_ctl() {
    local action="$1"
    if [ -z "$FPM_SERVICE" ]; then
        FPM_SERVICE="$(detect_fpm_service)"
    fi
    if [ -z "$FPM_SERVICE" ]; then
        echo "${yel}Warning: PHP-FPM service not found, skipping $action${end}"
        return 0
    fi
    systemctl "$action" "$FPM_SERVICE"
}

get_nginx_version() {
    nginx -v 2>&1 | sed -n 's|.*nginx/\([0-9.]\+\).*|\1|p'
}

adjust_vhost_http2_for_nginx_version() {
    local vhost_file=$1
    local nginx_version

    nginx_version=$(get_nginx_version)

    if [ -n "$nginx_version" ] && dpkg --compare-versions "$nginx_version" lt "1.25.1"; then
        sed -i 's/listen 443 ssl;/listen 443 ssl http2;/g' "$vhost_file"
        sed -i 's/^[[:space:]]*http2 on;/  # http2 on;/g' "$vhost_file"
    fi
}

# Ask the user to add domain name
while true; do
    clear
    clear
    echo "########################### SERVER CONFIGURED BY MIGUEL EMMARA ###########################"
    echo "                                   ${grn}INSTALL FILERUN${end}"
    echo ""
    echo "     __                                    "
    echo "    / /   ___  ____ ___  ____  ____  __  __"
    echo "   / /   / _ \/ __ \`__ \/ __ \/_  / / / / /"
    echo "  / /___/  __/ / / / / / /_/ / / /_/ /_/ /"
    echo " /_____/\___/_/ /_/ /_/ .___/ /___/\__, /"
    echo "                   /_/          /____/_/"
    echo ""
    echo "${grn}Press [CTRL + C] to cancel...${end}"

    echo "Note* this will erase all of your data on your domain folder, then install Filerun!"
    echo "Preferably install Filerun on your subdomain [eg, manage.domain.com]"
    echo "Feel free to backup any important files before hand!"
    echo ""
    echo "Here all the domain on you server"
    echo ""
    echo "_____________"
    echo "${blu}"
    ls -I default -I phpmyadmin -I filemanager -1 /etc/nginx/sites-enabled/
    echo "${end}_____________"
    echo ""
    read -p ${grn}"Please provide domain [eg, manage.domain.com]${end}: " domain
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

# Check if domain is not there
check_if_domain_exist() {
    FILE=/etc/nginx/sites-available/$domain
    file2=/var/www/$domain
    if [ -f "$FILE" ] || [ -f "$file2" ]; then
        clear
    else
        echo ""
        echo "$domain does not exist, please try again"
        exit
    fi
}

# Install Filerun
install_filerun() {
    rm -rf /var/www/$domain/*
    cd /var/www/$domain/
    wget -O FileRun.zip http://www.filerun.com/download-latest
    unzip FileRun.zip
    chown -R www-data:www-data /var/www/$domain
    chown -R www-data:www-data /var/www/$domain/system/data
    chown www-data:www-data /var/www/
    chown -R $USER:$USER /var/www/$domain       # JUST TO MAKE SURE
    chown -R www-data:www-data /var/www/$domain # JUST TO MAKE SURE
}

# Change vhost to no fastcgi cache.
change_vhost() {
    configName=$domain
    cd $sitesAvailable
    cp /root/Lempzy/scripts/vhost-nocache $sitesAvailable$domain
    adjust_vhost_http2_for_nginx_version "$sitesAvailable$configName"
    sed -i "s/domain.com/$domain/g" $sitesAvailable$configName
    sed -i "s/phpX.X/php$PHP_VERSION/g" $sitesAvailable$configName
}

# Create NEW Database For Filerun
create_filerun_database() {
    domainClear=${domain//./}                                                          # Domain name variable
    domainClear2=${domainClear//-/}                                                    # Domain name variable
    password_filerun=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1) # Generate random password and save it to password_filerun variable.

        mysql -uroot <<MYSQL_SCRIPT
        CREATE DATABASE filerun_db_$domainClear2;
        CREATE USER 'filerun_usr_$domainClear2'@'localhost' IDENTIFIED BY '$password_filerun';
        GRANT ALL PRIVILEGES ON filerun_db_$domainClear2.* TO 'filerun_usr_$domainClear2'@'localhost';
        FLUSH PRIVILEGES;
MYSQL_SCRIPT
}

# Restart nginx and php-fpm
restart_service() {
    echo "Restart Nginx & PHP-FPM ..."
    echo ""
    sleep 1
    systemctl restart nginx
    fpm_ctl restart
}

# Run
check_if_domain_exist
install_filerun
change_vhost
create_filerun_database
restart_service

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

echo "Complete! $domain has been installed with Filerun!"
echo "Navigate to ${grn}$domain${end} in your browser to configure Filerun"
echo ""
echo "Database Name: filerun_db_$domainClear2"
echo "User Name: filerun_usr_$domainClear2"
echo "Password: $password_filerun"
echo ""
