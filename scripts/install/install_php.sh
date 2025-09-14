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

# Install PHP
install_php() {
     # Check if a specific PHP version was selected
     if [[ -n "$SELECTED_PHP_VERSION" && "$SELECTED_PHP_VERSION" != "auto" ]]; then
          install_specific_php_version "$SELECTED_PHP_VERSION"
          return
     fi
     
     # Get OS Version for auto-detection
     OS_VERSION=$(lsb_release -rs)
     if [[ "${OS_VERSION}" == "10" ]]; then
          echo "${grn}Installing PHP ...${end}"
          apt install php7.3-fpm php-mysql -y
          apt install php7.3-common php7.3-zip php7.3-curl php7.3-xml php7.3-xmlrpc php7.3-json php7.3-mysql php7.3-pdo php7.3-gd php7.3-imagick php7.3-ldap php7.3-imap php7.3-mbstring php7.3-intl php7.3-cli php7.3-recode php7.3-tidy php7.3-bcmath php7.3-opcache -y
          echo ""
          sleep 1

     elif [[ "${OS_VERSION}" == "11" ]]; then
          echo "${grn}Installing PHP ...${end}"
          echo ""
          sleep 3
          apt install php7.4-fpm php-mysql -y
          apt-get install php7.4 php7.4-common php7.4-gd php7.4-mysql php7.4-imap php7.4-cli php7.4-cgi php-pear mcrypt imagemagick libruby php7.4-curl php7.4-intl php7.4-pspell php7.4-sqlite3 php7.4-tidy php7.4-xmlrpc php7.4-xsl memcached php-memcache php-imagick php7.4-zip php7.4-mbstring memcached php7.4-soap php7.4-fpm php7.4-opcache php-apcu -y
          echo ""
          sleep 1

     elif [[ "${OS_VERSION}" == "18.04" ]]; then
          echo "${grn}Installing PHP ...${end}"
          apt-get install software-properties-common
          add-apt-repository -y ppa:ondrej/php
          apt update
          apt install php7.3-fpm php-mysql -y
          apt install php7.3-common php7.3-zip php7.3-curl php7.3-xml php7.3-xmlrpc php7.3-json php7.3-mysql php7.3-pdo php7.3-gd php7.3-imagick php7.3-ldap php7.3-imap php7.3-mbstring php7.3-intl php7.3-cli php7.3-recode php7.3-tidy php7.3-bcmath php7.3-opcache -y
          apt-get purge php8.* -y
          apt-get autoclean
          apt-get autoremove -y
          echo ""
          sleep 1

     elif [[ "${OS_VERSION}" == "20.04" ]]; then
          echo "${grn}Installing PHP ...${end}"
          echo ""
          sleep 3
          apt install php7.4-fpm php-mysql -y
          apt-get install php7.4 php7.4-common php7.4-gd php7.4-mysql php7.4-imap php7.4-cli php7.4-cgi php-pear mcrypt imagemagick libruby php7.4-curl php7.4-intl php7.4-pspell php7.4-sqlite3 php7.4-tidy php7.4-xmlrpc php7.4-xsl memcached php-memcache php-imagick php7.4-zip php7.4-mbstring memcached php7.4-soap php7.4-fpm php7.4-opcache php-apcu -y
          echo ""
          sleep 1

     elif [[ "${OS_VERSION}" == "22.04" ]]; then
          echo "${grn}Installing PHP ...${end}"
          echo ""
          sleep 3
          apt install php8.1-fpm php-mysql -y
          apt-get install php8.1 php8.1-common php8.1-gd php8.1-mysql php8.1-imap php8.1-cli php8.1-cgi php-pear mcrypt imagemagick libruby php8.1-curl php8.1-intl php8.1-pspell php8.1-sqlite3 php8.1-tidy php8.1-xmlrpc php8.1-xsl memcached php-memcache php-imagick php8.1-zip php8.1-mbstring memcached php8.1-soap php8.1-fpm php8.1-opcache php-apcu -y
          echo ""
          sleep 1

     elif [[ "${OS_VERSION}" == "22.10" ]]; then
          echo "${grn}Installing PHP ...${end}"
          echo ""
          sleep 3
          apt install php8.1-fpm php-mysql -y
          apt-get install php8.1 php8.1-common php8.1-gd php8.1-mysql php8.1-imap php8.1-cli php8.1-cgi php-pear mcrypt imagemagick libruby php8.1-curl php8.1-intl php8.1-pspell php8.1-sqlite3 php8.1-tidy php8.1-xmlrpc php8.1-xsl memcached php-memcache php-imagick php8.1-zip php8.1-mbstring memcached php8.1-soap php8.1-fpm php8.1-opcache php-apcu -y
          echo ""
          sleep 1
          
     elif [[ "${OS_VERSION}" == "12" ]]; then
          echo "${grn}Installing PHP 8.2...${end}"
          echo ""
          sleep 3
          apt install php8.2-fpm php-mysql -y
          apt-get install php8.2 php8.2-common php8.2-gd php8.2-mysql php8.2-imap php8.2-cli php8.2-cgi php-pear mcrypt imagemagick libruby php8.2-curl php8.2-intl php8.2-pspell php8.2-sqlite3 php8.2-tidy php8.2-xmlrpc php8.2-xsl memcached php-memcache php-imagick php8.2-zip php8.2-mbstring memcached php8.2-soap php8.2-fpm php8.2-opcache php-apcu -y
          echo ""
          sleep 1

     elif [[ "${OS_VERSION}" == "13" ]]; then
          echo "${grn}Installing PHP 8.3...${end}"
          echo ""
          sleep 3
          apt install php8.3-fpm php-mysql -y
          apt-get install php8.3 php8.3-common php8.3-gd php8.3-mysql php8.3-imap php8.3-cli php8.3-cgi php-pear mcrypt imagemagick libruby php8.3-curl php8.3-intl php8.3-pspell php8.3-sqlite3 php8.3-tidy php8.3-xmlrpc php8.3-xsl memcached php-memcache php-imagick php8.3-zip php8.3-mbstring memcached php8.3-soap php8.3-fpm php8.3-opcache php-apcu -y
          echo ""
          sleep 1

     elif [[ "${OS_VERSION}" == "24.04" ]]; then
          echo "${grn}Installing PHP 8.3...${end}"
          echo ""
          sleep 3
          apt install php8.3-fpm php-mysql -y
          apt-get install php8.3 php8.3-common php8.3-gd php8.3-mysql php8.3-imap php8.3-cli php8.3-cgi php-pear mcrypt imagemagick libruby php8.3-curl php8.3-intl php8.3-pspell php8.3-sqlite3 php8.3-tidy php8.3-xmlrpc php8.3-xsl memcached php-memcache php-imagick php8.3-zip php8.3-mbstring memcached php8.3-soap php8.3-fpm php8.3-opcache php-apcu -y
          echo ""
          sleep 1

     else
          echo -e "${red}Sorry, This script is designed for DEBIAN (10, 11, 12, 13), UBUNTU (18.04, 20.04, 22.04, 22.10, 24.04)${end}"
          exit 1
     fi
}

# Configure PHP FPM
configure_php_fpm() {
     echo "${grn}Configure PHP FPM ...${end}"
     echo ""
     sleep 3

     # Get PHP Installed Version
     PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")

     if [[ "${PHP_VERSION}" == "7.2" ]]; then
          sed -i "s/max_execution_time = 30/max_execution_time = 360/g" /etc/php/7.2/fpm/php.ini
          sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/7.2/fpm/php.ini
          sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/7.2/fpm/php.ini
          sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/fpm/php.ini
          sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/7.2/fpm/php.ini
          sed -i "s/post_max_size = .*/post_max_size = 256M/" /etc/php/7.2/fpm/php.ini
          echo ""
          sleep 1

     elif [[ "${PHP_VERSION}" == "7.3" ]]; then
          sed -i "s/max_execution_time = 30/max_execution_time = 360/g" /etc/php/7.3/fpm/php.ini
          sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/7.3/fpm/php.ini
          sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/7.3/fpm/php.ini
          sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.3/fpm/php.ini
          sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/7.3/fpm/php.ini
          sed -i "s/post_max_size = .*/post_max_size = 256M/" /etc/php/7.3/fpm/php.ini
          echo ""
          sleep 1

     elif [[ "${PHP_VERSION}" == "7.4" ]]; then
          sed -i "s/max_execution_time = 30/max_execution_time = 360/g" /etc/php/7.4/fpm/php.ini
          sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/7.4/fpm/php.ini
          sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/7.4/fpm/php.ini
          sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.4/fpm/php.ini
          sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/7.4/fpm/php.ini
          sed -i "s/post_max_size = .*/post_max_size = 256M/" /etc/php/7.4/fpm/php.ini
          echo ""
          sleep 1

     elif [[ "${PHP_VERSION}" == "8.0" ]]; then
          sed -i "s/max_execution_time = 30/max_execution_time = 360/g" /etc/php/8.0/fpm/php.ini
          sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/8.0/fpm/php.ini
          sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.0/fpm/php.ini
          sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.0/fpm/php.ini
          sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/8.0/fpm/php.ini
          sed -i "s/post_max_size = .*/post_max_size = 256M/" /etc/php/8.0/fpm/php.ini
          echo ""
          sleep 1

     elif [[ "${PHP_VERSION}" == "8.1" ]]; then
          sed -i "s/max_execution_time = 30/max_execution_time = 360/g" /etc/php/8.1/fpm/php.ini
          sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/8.1/fpm/php.ini
          sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.1/fpm/php.ini
          sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.1/fpm/php.ini
          sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/8.1/fpm/php.ini
          sed -i "s/post_max_size = .*/post_max_size = 256M/" /etc/php/8.1/fpm/php.ini
          echo ""
          sleep 1
          
     elif [[ "${PHP_VERSION}" == "8.2" ]]; then
          sed -i "s/max_execution_time = 30/max_execution_time = 360/g" /etc/php/8.2/fpm/php.ini
          sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/8.2/fpm/php.ini
          sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.2/fpm/php.ini
          sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.2/fpm/php.ini
          sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/8.2/fpm/php.ini
          sed -i "s/post_max_size = .*/post_max_size = 256M/" /etc/php/8.2/fpm/php.ini
          echo ""
          sleep 1

     elif [[ "${PHP_VERSION}" == "8.3" ]]; then
          sed -i "s/max_execution_time = 30/max_execution_time = 360/g" /etc/php/8.3/fpm/php.ini
          sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/8.3/fpm/php.ini
          sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.3/fpm/php.ini
          sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.3/fpm/php.ini
          sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/8.3/fpm/php.ini
          sed -i "s/post_max_size = .*/post_max_size = 256M/" /etc/php/8.3/fpm/php.ini
          echo ""
          sleep 1

     elif [[ "${PHP_VERSION}" == "8.4" ]]; then
          sed -i "s/max_execution_time = 30/max_execution_time = 360/g" /etc/php/8.4/fpm/php.ini
          sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/8.4/fpm/php.ini
          sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.4/fpm/php.ini
          sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.4/fpm/php.ini
          sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/8.4/fpm/php.ini
          sed -i "s/post_max_size = .*/post_max_size = 256M/" /etc/php/8.4/fpm/php.ini
          echo ""
          sleep 1
          

     else
          echo -e "${red}Sorry, This script is designed for DEBIAN (10, 11, 12, 13), UBUNTU (18.04, 20.04, 22.04, 22.10, 24.04)${end}"
          exit 1
     fi
}

# Function to install specific PHP version
install_specific_php_version() {
     local php_version="$1"
     echo "${grn}Installing PHP $php_version...${end}"
     echo ""
     sleep 3
     
     # Add Ondrej PHP repository for all versions
     apt-get update
     apt-get install -y software-properties-common
     add-apt-repository -y ppa:ondrej/php
     apt-get update
     
     # Install the specific PHP version
     case $php_version in
          "7.4")
               apt install php7.4-fpm php-mysql -y
               apt-get install php7.4 php7.4-common php7.4-gd php7.4-mysql php7.4-imap php7.4-cli php7.4-cgi php-pear mcrypt imagemagick libruby php7.4-curl php7.4-intl php7.4-pspell php7.4-sqlite3 php7.4-tidy php7.4-xmlrpc php7.4-xsl memcached php-memcache php-imagick php7.4-zip php7.4-mbstring memcached php7.4-soap php7.4-fpm php7.4-opcache php-apcu -y
               ;;
          "8.0")
               apt install php8.0-fpm php-mysql -y
               apt-get install php8.0 php8.0-common php8.0-gd php8.0-mysql php8.0-imap php8.0-cli php8.0-cgi php-pear mcrypt imagemagick libruby php8.0-curl php8.0-intl php8.0-pspell php8.0-sqlite3 php8.0-tidy php8.0-xmlrpc php8.0-xsl memcached php-memcache php-imagick php8.0-zip php8.0-mbstring memcached php8.0-soap php8.0-fpm php8.0-opcache php-apcu -y
               ;;
          "8.1")
               apt install php8.1-fpm php-mysql -y
               apt-get install php8.1 php8.1-common php8.1-gd php8.1-mysql php8.1-imap php8.1-cli php8.1-cgi php-pear mcrypt imagemagick libruby php8.1-curl php8.1-intl php8.1-pspell php8.1-sqlite3 php8.1-tidy php8.1-xmlrpc php8.1-xsl memcached php-memcache php-imagick php8.1-zip php8.1-mbstring memcached php8.1-soap php8.1-fpm php8.1-opcache php-apcu -y
               ;;
          "8.2")
               apt install php8.2-fpm php-mysql -y
               apt-get install php8.2 php8.2-common php8.2-gd php8.2-mysql php8.2-imap php8.2-cli php8.2-cgi php-pear mcrypt imagemagick libruby php8.2-curl php8.2-intl php8.2-pspell php8.2-sqlite3 php8.2-tidy php8.2-xmlrpc php8.2-xsl memcached php-memcache php-imagick php8.2-zip php8.2-mbstring memcached php8.2-soap php8.2-fpm php8.2-opcache php-apcu -y
               ;;
          "8.3")
               apt install php8.3-fpm php-mysql -y
               apt-get install php8.3 php8.3-common php8.3-gd php8.3-mysql php8.3-imap php8.3-cli php8.3-cgi php-pear mcrypt imagemagick libruby php8.3-curl php8.3-intl php8.3-pspell php8.3-sqlite3 php8.3-tidy php8.3-xmlrpc php8.3-xsl memcached php-memcache php-imagick php8.3-zip php8.3-mbstring memcached php8.3-soap php8.3-fpm php8.3-opcache php-apcu -y
               ;;
          *)
               echo "${red}Unsupported PHP version: $php_version${end}"
               return 1
               ;;
     esac
     
     # Set the selected PHP version as default
     echo "${grn}Setting PHP $php_version as default...${end}"
     
     # Install alternatives for PHP binaries
     update-alternatives --install /usr/bin/php php /usr/bin/php$php_version 100
     update-alternatives --install /usr/bin/phar phar /usr/bin/phar$php_version 100
     update-alternatives --install /usr/bin/phar.phar phar.phar /usr/bin/phar.phar$php_version 100
     
     # Set the selected PHP version as default
     update-alternatives --set php /usr/bin/php$php_version 2>/dev/null || true
     update-alternatives --set phar /usr/bin/phar$php_version 2>/dev/null || true
     update-alternatives --set phar.phar /usr/bin/phar.phar$php_version 2>/dev/null || true
     
     # Disable other PHP-FPM services and enable the selected one
     systemctl stop php*-fpm 2>/dev/null || true
     systemctl disable php*-fpm 2>/dev/null || true
     systemctl enable php$php_version-fpm
     systemctl start php$php_version-fpm
     
     # Verify installation
     if php -v | grep -q "PHP $php_version"; then
          echo "${grn}PHP $php_version installed and configured successfully${end}"
     else
          echo "${yel}Warning: PHP version verification failed, but installation completed${end}"
     fi
     esac
     
     echo ""
     sleep 1
}

# Run
install_php
configure_php_fpm
