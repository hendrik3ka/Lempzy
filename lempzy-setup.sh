#!/bin/bash

# Script author: Muhamad Miguel Emmara
# Script site: https://www.miguelemmara.me
# Lempzy - One Click LEMP Server Stack Installation Script
#--------------------------------------------------
# Installation List:
# Nginx
# MariaDB (We will use MariaDB as our database)
# PHP
# UFW Firewall
# Memcached / Redis / Both / Skip
# FASTCGI_CACHE
# IONCUBE
# MCRYPT
# HTOP
# NETSTAT
# OPEN SSL
# AB BENCHMARKING TOOL
# ZIP AND UNZIP
# FFMPEG AND IMAGEMAGICK
# CURL
# GIT
# COMPOSER
#--------------------------------------------------

set -e

# Colours
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

# Array to track failed installations
FAILED_INSTALLATIONS=()

# Function to check if a package is installed
check_package_installed() {
    local package_name="$1"
    if dpkg -l | grep -q "^ii.*$package_name"; then
        return 0  # Package is installed
    else
        return 1  # Package is not installed
    fi
}

# Function to check if a command exists
check_command_exists() {
    local command_name="$1"
    if command -v "$command_name" >/dev/null 2>&1; then
        return 0  # Command exists
    else
        return 1  # Command does not exist
    fi
}

# Function to add failed installation to tracking array
add_failed_installation() {
    local component="$1"
    FAILED_INSTALLATIONS+=("$component")
    echo "${yel}Warning: Failed to install $component, continuing with next component...${end}"
}

# Function to report installation summary
report_installation_summary() {
    echo ""
    echo "${grn}=== INSTALLATION SUMMARY ===${end}"
    if [ ${#FAILED_INSTALLATIONS[@]} -eq 0 ]; then
        echo "${grn}All components installed successfully!${end}"
    else
        echo "${yel}The following components failed to install:${end}"
        for failed in "${FAILED_INSTALLATIONS[@]}"; do
            echo "${red}- $failed${end}"
        done
        echo "${yel}You may need to install these manually later.${end}"
    fi
    echo ""
}

# Function to display countdown and get user input
countdown_input() {
    local prompt="$1"
    local default_choice="$2"
    local choice=""
    local timeout=60  # Timeout in seconds
    local countdown=$timeout

    # Send display output to stderr
    echo "${yel}Auto-selecting default option [$default_choice] in $timeout seconds...${end}" >&2
    echo "${grn}Press Enter to use default, or type your choice:${end}" >&2
    echo "" >&2

    # Display countdown timer
    while [ $countdown -gt 0 ]; do
        printf "\r${cyn}$prompt (auto-select in %2d seconds): ${end}" "$countdown" >&2
        # Attempt to read input with a 1-second timeout
        if read -t 1 -r choice; then
            # Input received, break the loop
            break
        fi
        ((countdown--))
    done

    # If no input was provided (timeout or empty input), use default
    if [ -z "$choice" ]; then
        choice="$default_choice"
        echo "" >&2  # Newline for clean output
        echo "${yel}No input provided, using default: $default_choice${end}" >&2
    else
        echo "" >&2  # Newline for clean output
    fi

    # Return the choice to stdout
    echo "$choice"
}

# To Ensure Correct Os Supported Version Is Use
OS_VERSION=$(lsb_release -rs)
if [[ "${OS_VERSION}" != "10" ]] && [[ "${OS_VERSION}" != "11" ]] && [[ "${OS_VERSION}" != "12" ]] && [[ "${OS_VERSION}" != "13" ]] && [[ "${OS_VERSION}" != "18.04" ]] && [[ "${OS_VERSION}" != "20.04" ]] && [[ "${OS_VERSION}" != "22.04" ]] && [[ "${OS_VERSION}" != "22.10" ]] && [[ "${OS_VERSION}" != "24.04" ]]; then
     echo -e "${red}Sorry, This script is designed for DEBIAN (10, 11, 12, 13), UBUNTU (18.04, 20.04, 22.04, 22.10, 24.04)${end}"
     exit 1
fi

# To ensure script run as root
if [ "$EUID" -ne 0 ]; then
     echo "${red}Please run this script as root user${end}"
     exit 1
fi

### Greetings
clear
echo ""
echo "******************************************************************************************"
echo " *   *    *****     ***     *   *    *****    *        *****    *****     ***     *   * "
echo " *   *      *      *   *    *   *    *        *          *      *        *   *    *   * "
echo " ** **      *      *        *   *    *        *          *      *        *        *   * "
echo " * * *      *      * ***    *   *    ****     *          *      ****     *        ***** "
echo " *   *      *      *   *    *   *    *        *          *      *        *        *   * "
echo " *   *      *      *   *    *   *    *        *          *      *        *   *    *   * "
echo " *   *    *****     ***      ***     *****    *****      *      *****     ***     *   * "
echo "******************************************************************************************"
echo ""

# Update os
UPDATE_OS=scripts/install/update_os.sh

if test -f "$UPDATE_OS"; then
     source $UPDATE_OS
     # Check if Lempzy directory exists before navigating to it
     if [ -d "$HOME/Lempzy" ]; then
          cd && cd && cd Lempzy
     else
          echo "${yel}Lempzy directory not found, staying in current directory${end}"
          # Continue with script execution from current directory
     fi
else
     echo "${red}Cannot find OS update script, continuing without OS update${end}"
     # Continue script execution instead of exiting
fi

# Installing UFW Firewall
INSTALL_UFW_FIREWALL=scripts/install/install_firewall.sh

if test -f "$INSTALL_UFW_FIREWALL"; then
     source $INSTALL_UFW_FIREWALL
     if [ -d "$HOME/Lempzy" ]; then
          cd && cd Lempzy
     else
          echo "${yel}Lempzy directory not found, staying in current directory${end}"
          # Continue with script execution from current directory
     fi
else
     echo "${red}Cannot Install UFW Firewall${end}"
     exit
fi

# Install MariaDB
echo "${grn}=== MARIADB VERSION SELECTION ===${end}"
echo "${yel}Choose your preferred MariaDB version:${end}"
echo "${blu}1) MariaDB 10.11 (LTS) ${grn}[DEFAULT - RECOMMENDED]${end}${end}"
echo "${blu}2) MariaDB 11.4 (LTS - Latest)${end}"
echo "${blu}3) MariaDB 10.1 (Legacy - EOL)${end}"
echo ""
mariadb_choice=$(countdown_input "${cyn}Enter your choice (1-3): ${end}" "1")
# Trim whitespace from input
mariadb_choice=$(echo "$mariadb_choice" | tr -d '[:space:]')

# Set MariaDB version based on user choice
case $mariadb_choice in
    "1")
        SELECTED_MARIADB_VERSION="10.11"
        echo "${grn}Selected MariaDB 10.11 (LTS)${end}"
        ;;
    "2")
        SELECTED_MARIADB_VERSION="11.4"
        echo "${grn}Selected MariaDB 11.4 (LTS)${end}"
        ;;
    "3")
        SELECTED_MARIADB_VERSION="10.1"
        echo "${yel}Warning: MariaDB 10.1 is End-of-Life (EOL) and no longer receives security updates${end}"
        echo "${grn}Selected MariaDB 10.1 (Legacy)${end}"
        ;;
    *)
        echo "${red}Invalid choice. Using default MariaDB 10.11...${end}"
        SELECTED_MARIADB_VERSION="10.11"
        ;;
esac

INSTALL_MARIADB=scripts/install/install_mariadb.sh

# Check if MariaDB is already installed
if check_command_exists "mysql" || check_package_installed "mariadb-server"; then
    echo "${grn}MariaDB is already installed, skipping...${end}"
else
    if test -f "$INSTALL_MARIADB"; then
        echo "${grn}Installing MariaDB $SELECTED_MARIADB_VERSION...${end}"
        # Export the selected MariaDB version for the install script to use
        export SELECTED_MARIADB_VERSION
        if source "$INSTALL_MARIADB"; then
            echo "${grn}MariaDB installed successfully${end}"
        else
            add_failed_installation "MariaDB"
        fi
        # Return to the script directory
        cd && cd Lempzy
    else
        echo "${red}Cannot find MariaDB installation script${end}"
        add_failed_installation "MariaDB (script not found)"
    fi
fi

echo ""

# Install PHP And Configure PHP
echo "${grn}=== PHP VERSION SELECTION ===${end}"
echo "${yel}Choose your preferred PHP version:${end}"
echo "${blu}1) PHP 7.4${end}"
echo "${blu}2) PHP 8.0${end}"
echo "${blu}3) PHP 8.1${end}"
echo "${blu}4) PHP 8.2${end}"
echo "${blu}5) PHP 8.3 ${grn}[DEFAULT]${end}${end}"
echo "${blu}6) Auto-detect based on OS${end}"
echo ""
php_choice=$(countdown_input "${cyn}Enter your choice (1-6): ${end}" "5")
# Trim whitespace from input
php_choice=$(echo "$php_choice" | tr -d '[:space:]')

# Set PHP version based on user choice
case $php_choice in
    "1")
        SELECTED_PHP_VERSION="7.4"
        echo "${grn}Selected PHP 7.4${end}"
        ;;
    "2")
        SELECTED_PHP_VERSION="8.0"
        echo "${grn}Selected PHP 8.0${end}"
        ;;
    "3")
        SELECTED_PHP_VERSION="8.1"
        echo "${grn}Selected PHP 8.1${end}"
        ;;
    "4")
        SELECTED_PHP_VERSION="8.2"
        echo "${grn}Selected PHP 8.2${end}"
        ;;
    "5")
        SELECTED_PHP_VERSION="8.3"
        echo "${grn}Selected PHP 8.3${end}"
        ;;
    "6"|"")
        SELECTED_PHP_VERSION="auto"
        echo "${grn}Using auto-detection based on OS version${end}"
        ;;
    *)
        echo "${red}Invalid choice. Using auto-detection...${end}"
        SELECTED_PHP_VERSION="auto"
        ;;
esac

INSTALL_PHP=scripts/install/install_php.sh

# Check if PHP is already installed
if check_command_exists "php"; then
    CURRENT_PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    echo "${grn}PHP $CURRENT_PHP_VERSION is already installed, skipping...${end}"
else
    if test -f "$INSTALL_PHP"; then
        echo "${grn}Installing PHP...${end}"
        # Export the selected PHP version for the install script to use
        export SELECTED_PHP_VERSION
        if source "$INSTALL_PHP"; then
            echo "${grn}PHP installed successfully${end}"
        else
            add_failed_installation "PHP"
        fi
        # Return to the script directory
        cd && cd Lempzy
    else
        echo "${red}Cannot find PHP installation script${end}"
        add_failed_installation "PHP (script not found)"
    fi
fi

echo ""

# Install, Start, And Configure nginx
INSTALL_NGINX=scripts/install/install_nginx.sh

if test -f "$INSTALL_NGINX"; then
     source $INSTALL_NGINX
     if [ -d "$HOME/Lempzy" ]; then
          cd && cd Lempzy
     else
          echo "${yel}Lempzy directory not found, staying in current directory${end}"
          # Continue with script execution from current directory
     fi
else
     echo "${red}Cannot Install Nginx${end}"
     exit
fi

# Install Caching Solution (Memcached/Redis)
echo "${grn}=== CACHING SOLUTION SELECTION ===${end}"
echo "${yel}Choose your preferred caching solution:${end}"
echo "${blu}1) Install Memcached only${end}"
echo "${blu}2) Install Redis only ${grn}[DEFAULT]${end}${end}"
echo "${blu}3) Install both Memcached and Redis${end}"
echo "${blu}4) Skip caching installation${end}"
echo ""
cache_choice=$(countdown_input "${cyn}Enter your choice (1-4): ${end}" "2")
# Trim whitespace from input
cache_choice=$(echo "$cache_choice" | tr -d '[:space:]')

case $cache_choice in
    "1")
        echo "${grn}Installing Memcached...${end}"
        INSTALL_MEMCACHED=scripts/install/install_memcached.sh
        
        # Check if memcached is already installed
        if check_package_installed "memcached" || check_command_exists "memcached"; then
            echo "${grn}Memcached is already installed, skipping...${end}"
        else
            if test -f "$INSTALL_MEMCACHED"; then
                if source "$INSTALL_MEMCACHED"; then
                    echo "${grn}Memcached installed successfully${end}"
                else
                    add_failed_installation "Memcached"
                fi
                cd && cd Lempzy
            else
                echo "${red}Cannot find Memcached installation script${end}"
                add_failed_installation "Memcached (script not found)"
            fi
        fi
        ;;
    "2")
        echo "${grn}Installing Redis...${end}"
        INSTALL_REDIS=scripts/install/install_redis.sh
        INSTALL_PHP_REDIS=scripts/install/install_php_redis.sh
        
        # Check if redis is already installed
        if check_command_exists "redis-server" || check_package_installed "redis-server"; then
            echo "${grn}Redis is already installed, skipping server installation...${end}"
        else
            if test -f "$INSTALL_REDIS"; then
                if source "$INSTALL_REDIS"; then
                    echo "${grn}Redis installed successfully${end}"
                else
                    add_failed_installation "Redis"
                fi
                cd && cd Lempzy
            else
                echo "${red}Cannot find Redis installation script${end}"
                add_failed_installation "Redis (script not found)"
            fi
        fi

        # Check if PHP Redis extension is installed; if not, install it
        if php -m 2>/dev/null | grep -qi "^redis$\|^redis "; then
            echo "${grn}PHP Redis extension is already installed, skipping...${end}"
        else
            if test -f "$INSTALL_PHP_REDIS"; then
                echo "${grn}Installing PHP Redis extension...${end}"
                if source "$INSTALL_PHP_REDIS"; then
                    echo "${grn}PHP Redis extension installed successfully${end}"
                else
                    add_failed_installation "PHP Redis extension"
                fi
                cd && cd Lempzy
            else
                echo "${red}Cannot find PHP Redis extension installation script${end}"
                add_failed_installation "PHP Redis extension (script not found)"
            fi
        fi
        ;;
    "3")
        echo "${grn}Installing both Memcached and Redis...${end}"
        
        # Install Memcached
        INSTALL_MEMCACHED=scripts/install/install_memcached.sh
        if check_package_installed "memcached" || check_command_exists "memcached"; then
            echo "${grn}Memcached is already installed, skipping...${end}"
        else
            if test -f "$INSTALL_MEMCACHED"; then
                echo "${grn}Installing Memcached...${end}"
                if source "$INSTALL_MEMCACHED"; then
                    echo "${grn}Memcached installed successfully${end}"
                else
                    add_failed_installation "Memcached"
                fi
                cd && cd Lempzy
            else
                echo "${red}Cannot find Memcached installation script${end}"
                add_failed_installation "Memcached (script not found)"
            fi
        fi
        
        # Install Redis
        INSTALL_REDIS=scripts/install/install_redis.sh
        INSTALL_PHP_REDIS=scripts/install/install_php_redis.sh
        if check_command_exists "redis-server" || check_package_installed "redis-server"; then
            echo "${grn}Redis is already installed, skipping server installation...${end}"
        else
            if test -f "$INSTALL_REDIS"; then
                echo "${grn}Installing Redis...${end}"
                if source "$INSTALL_REDIS"; then
                    echo "${grn}Redis installed successfully${end}"
                else
                    add_failed_installation "Redis"
                fi
                cd && cd Lempzy
            else
                echo "${red}Cannot find Redis installation script${end}"
                add_failed_installation "Redis (script not found)"
            fi
        fi

        # Check if PHP Redis extension is installed; if not, install it
        if php -m 2>/dev/null | grep -qi "^redis$\|^redis "; then
            echo "${grn}PHP Redis extension is already installed, skipping...${end}"
        else
            if test -f "$INSTALL_PHP_REDIS"; then
                echo "${grn}Installing PHP Redis extension...${end}"
                if source "$INSTALL_PHP_REDIS"; then
                    echo "${grn}PHP Redis extension installed successfully${end}"
                else
                    add_failed_installation "PHP Redis extension"
                fi
                cd && cd Lempzy
            else
                echo "${red}Cannot find PHP Redis extension installation script${end}"
                add_failed_installation "PHP Redis extension (script not found)"
            fi
        fi
        ;;
    "4")
        echo "${yel}Skipping caching solution installation...${end}"
        ;;
    *)
        echo "${red}Invalid choice. Skipping caching installation...${end}"
        ;;
esac

echo ""

# Install Ioncube
INSTALL_IONCUBE=scripts/install/install_ioncube.sh

# Check if ioncube is already installed (check for ioncube loader in PHP)
if php -m 2>/dev/null | grep -q "ionCube"; then
    echo "${grn}Ioncube is already installed, skipping...${end}"
else
    if test -f "$INSTALL_IONCUBE"; then
        echo "${grn}Installing Ioncube...${end}"
        if source "$INSTALL_IONCUBE"; then
            echo "${grn}Ioncube installed successfully${end}"
        else
            add_failed_installation "Ioncube"
        fi
        # Return to the script directory
        cd && cd Lempzy
    else
        echo "${red}Cannot find Ioncube installation script${end}"
        add_failed_installation "Ioncube (script not found)"
    fi
fi

# Note: Mcrypt installation removed - deprecated since PHP 7.1, removed in PHP 7.2+
# Modern PHP versions (8.0+) use OpenSSL or Sodium for encryption instead
# For legacy applications requiring mcrypt, consider using mcrypt_compat library

# Install HTOP
INSTALL_HTOP=scripts/install/install_htop.sh

# Check if htop is already installed
if check_command_exists "htop" || check_package_installed "htop"; then
    echo "${grn}HTOP is already installed, skipping...${end}"
else
    if test -f "$INSTALL_HTOP"; then
        echo "${grn}Installing HTOP...${end}"
        if source "$INSTALL_HTOP"; then
            echo "${grn}HTOP installed successfully${end}"
        else
            add_failed_installation "HTOP"
        fi
        # Return to the script directory
        cd && cd Lempzy
    else
        echo "${red}Cannot find HTOP installation script${end}"
        add_failed_installation "HTOP (script not found)"
    fi
fi

# Install Netstat
INSTALL_NETSTAT=scripts/install/install_netstat.sh

# Check if netstat is already installed
if check_command_exists "netstat" || check_package_installed "net-tools"; then
    echo "${grn}Netstat is already installed, skipping...${end}"
else
    if test -f "$INSTALL_NETSTAT"; then
        echo "${grn}Installing Netstat...${end}"
        if source "$INSTALL_NETSTAT"; then
            echo "${grn}Netstat installed successfully${end}"
        else
            add_failed_installation "Netstat"
        fi
        # Return to the script directory
        cd && cd Lempzy
    else
        echo "${red}Cannot find Netstat installation script${end}"
        add_failed_installation "Netstat (script not found)"
    fi
fi

# Install SSL Solution (OpenSSL/Let's Encrypt)
echo "${grn}=== SSL SOLUTION SELECTION ===${end}"
echo "${yel}Choose your preferred SSL solution:${end}"
echo "${blu}1) Install OpenSSL only${end}"
echo "${blu}2) Install Let's Encrypt (Certbot)${end}"
echo "${blu}3) Install both OpenSSL and Let's Encrypt ${grn}[DEFAULT]${end}${end}"
echo "${blu}4) Skip SSL installation${end}"
echo ""
ssl_choice=$(countdown_input "${cyn}Enter your choice (1-4): ${end}" "3")
# Trim whitespace from input
ssl_choice=$(echo "$ssl_choice" | tr -d '[:space:]')

case $ssl_choice in
    "1")
        echo "${grn}Installing OpenSSL...${end}"
        INSTALL_OPENSSL=scripts/install/install_openssl.sh
        
        if test -f "$INSTALL_OPENSSL"; then
            if source "$INSTALL_OPENSSL"; then
                echo "${grn}OpenSSL installed successfully${end}"
            else
                add_failed_installation "OpenSSL"
            fi
            cd && cd Lempzy
        else
            echo "${red}Cannot find OpenSSL installation script${end}"
            add_failed_installation "OpenSSL (script not found)"
        fi
    
        ;;
    "2")
        echo "${grn}Installing Let's Encrypt (Certbot)...${end}"
        INSTALL_LETSENCRYPT=scripts/install/install_letsencrypt.sh
        
        # Check if certbot is already installed
        if check_command_exists "certbot"; then
            echo "${grn}Let's Encrypt (Certbot) is already installed, skipping...${end}"
        else
            if test -f "$INSTALL_LETSENCRYPT"; then
                if source "$INSTALL_LETSENCRYPT"; then
                    echo "${grn}Let's Encrypt installed successfully${end}"
                else
                    add_failed_installation "Let's Encrypt"
                fi
                cd && cd Lempzy
            else
                echo "${red}Cannot find Let's Encrypt installation script${end}"
                add_failed_installation "Let's Encrypt (script not found)"
            fi
        fi
        ;;
    "3")
        echo "${grn}Installing both OpenSSL and Let's Encrypt...${end}"
        
        # Install OpenSSL
        INSTALL_OPENSSL=scripts/install/install_openssl.sh
        if test -f "$INSTALL_OPENSSL"; then
            echo "${grn}Installing OpenSSL...${end}"
            if source "$INSTALL_OPENSSL"; then
                echo "${grn}OpenSSL installed successfully${end}"
            else
                add_failed_installation "OpenSSL"
            fi
            cd && cd Lempzy
        else
            echo "${red}Cannot find OpenSSL installation script${end}"
            add_failed_installation "OpenSSL (script not found)"
        fi
        
        # Install Let's Encrypt
        INSTALL_LETSENCRYPT=scripts/install/install_letsencrypt.sh
        if check_command_exists "certbot"; then
            echo "${grn}Let's Encrypt (Certbot) is already installed, skipping...${end}"
        else
            if test -f "$INSTALL_LETSENCRYPT"; then
                echo "${grn}Installing Let's Encrypt...${end}"
                if source "$INSTALL_LETSENCRYPT"; then
                    echo "${grn}Let's Encrypt installed successfully${end}"
                else
                    add_failed_installation "Let's Encrypt"
                fi
                cd && cd Lempzy
            else
                echo "${red}Cannot find Let's Encrypt installation script${end}"
                add_failed_installation "Let's Encrypt (script not found)"
            fi
        fi
        ;;
    "4")
        echo "${yel}Skipping SSL installation...${end}"
        ;;
    *)
        echo "${red}Invalid choice. Skipping SSL installation...${end}"
        ;;
esac

echo ""

# Install AB BENCHMARKING TOOL
INSTALL_AB=scripts/install/install_ab.sh

# Check if ab (Apache Bench) is already installed
if check_command_exists "ab" || check_package_installed "apache2-utils"; then
    echo "${grn}AB Benchmarking Tool is already installed, skipping...${end}"
else
    if test -f "$INSTALL_AB"; then
        echo "${grn}Installing AB Benchmarking Tool...${end}"
        if source "$INSTALL_AB"; then
            echo "${grn}AB Benchmarking Tool installed successfully${end}"
        else
            add_failed_installation "AB Benchmarking Tool"
        fi
        # Return to the script directory
        cd && cd Lempzy
    else
        echo "${red}Cannot find AB installation script${end}"
        add_failed_installation "AB Benchmarking Tool (script not found)"
    fi
fi

# Install ZIP AND UNZIP
INSTALL_ZIPS=scripts/install/install_zips.sh

# Check if zip and unzip are already installed
if check_command_exists "zip" && check_command_exists "unzip"; then
    echo "${grn}ZIP and UNZIP are already installed, skipping...${end}"
else
    if test -f "$INSTALL_ZIPS"; then
        echo "${grn}Installing ZIP and UNZIP...${end}"
        if source "$INSTALL_ZIPS"; then
            echo "${grn}ZIP and UNZIP installed successfully${end}"
        else
            add_failed_installation "ZIP and UNZIP"
        fi
        # Return to the script directory
        cd && cd Lempzy
    else
        echo "${red}Cannot find ZIP installation script${end}"
        add_failed_installation "ZIP and UNZIP (script not found)"
    fi
fi

# Install FFMPEG and IMAGEMAGICK
INSTALL_FFMPEG=scripts/install/install_ffmpeg.sh

# Check if ffmpeg and imagemagick are already installed
if check_command_exists "ffmpeg" && check_command_exists "convert"; then
    echo "${grn}FFMPEG and ImageMagick are already installed, skipping...${end}"
else
    if test -f "$INSTALL_FFMPEG"; then
        echo "${grn}Installing FFMPEG and ImageMagick...${end}"
        if source "$INSTALL_FFMPEG"; then
            echo "${grn}FFMPEG and ImageMagick installed successfully${end}"
        else
            add_failed_installation "FFMPEG and ImageMagick"
        fi
        # Return to the script directory
        cd && cd Lempzy
    else
        echo "${red}Cannot find FFMPEG installation script${end}"
        add_failed_installation "FFMPEG and ImageMagick (script not found)"
    fi
fi

# Install Git And Curl
INSTALL_GIT=scripts/install/install_git.sh

# Check if git and curl are already installed
if check_command_exists "git" && check_command_exists "curl"; then
    echo "${grn}Git and Curl are already installed, skipping...${end}"
else
    if test -f "$INSTALL_GIT"; then
        echo "${grn}Installing Git and Curl...${end}"
        if source "$INSTALL_GIT"; then
            echo "${grn}Git and Curl installed successfully${end}"
        else
            add_failed_installation "Git and Curl"
        fi
        # Return to the script directory
        cd && cd Lempzy
    else
        echo "${red}Cannot find Git installation script${end}"
        add_failed_installation "Git and Curl (script not found)"
    fi
fi

# Install Composer
INSTALL_COMPOSER=scripts/install/install_composer.sh

# Check if composer is already installed
if check_command_exists "composer"; then
    echo "${grn}Composer is already installed, skipping...${end}"
else
    if test -f "$INSTALL_COMPOSER"; then
        echo "${grn}Installing Composer...${end}"
        if source "$INSTALL_COMPOSER"; then
            echo "${grn}Composer installed successfully${end}"
        else
            add_failed_installation "Composer"
        fi
        # Return to the script directory
        cd && cd Lempzy
    else
        echo "${red}Cannot find Composer installation script${end}"
        add_failed_installation "Composer (script not found)"
    fi
fi

# Report installation summary
report_installation_summary

# Change Login Greeting
change_login_greetings() {
    echo "${grn}Change Login Greeting ...${end}"
    echo ""
    sleep 3

cd ~
cat > .bashrc << EOF
echo "########################### SERVER CONFIGURED BY LEMPZY ###########################"
echo " ######################## FULL INSTRUCTIONS GO TO MIGUELEMMARA.ME ####################### "
echo ""
echo "     __                                    "
echo "    / /   ___  ____ ___  ____  ____  __  __"
echo "   / /   / _ \/ __ \\\`__ \/ __ \/_  / / / / /"
echo "  / /___/  __/ / / / / / /_/ / / /_/ /_/ /"
echo " /_____/\___/_/ /_/ /_/ .___/ /___/\__, /"
echo "                   /_/          /____/_/"
echo ""
./lempzy.sh
EOF

    echo ""
    cd && cd Lempzy
    sleep 1
}

change_login_greetings

# Menu Script Permission Setting
cp scripts/lempzy.sh /root
dos2unix /root/lempzy.sh
chmod +x /root/lempzy.sh

# Success Prompt
clear

# Success Prompt
echo "Lemzpy - LEMP Auto Installer BY Miguel Emmara $(date)"
echo "******************************************************************************************"
echo "              *   *    *****    *         ***      ***     *   *    ***** 	"
echo "              *   *    *        *        *   *    *   *    *   *    *		"
echo "              *   *    *        *        *        *   *    ** **    *		"
echo "              *   *    ****     *        *        *   *    * * *    ****	"
echo "              * * *    *        *        *        *   *    *   *    *		"
echo "              * * *    *        *        *   *    *   *    *   *    *		"
echo "               * *     *****    *****     ***      ***     *   *    *****	"
echo ""

echo "		                  *****     ***	"
echo "			      	    *      *   *	"
echo "			      	    *      *   *	"
echo "			      	    *      *   *	"
echo "			      	    *      *   *	"
echo "			      	    *      *   *	"
echo "			      	    *       ***	"
echo ""

echo " *   *    *****     ***     *   *    *****    *        *****    *****     ***     *   * "
echo " *   *      *      *   *    *   *    *        *          *      *        *   *    *   * "
echo " ** **      *      *        *   *    *        *          *      *        *        *   * "
echo " * * *      *      * ***    *   *    ****     *          *      ****     *        ***** "
echo " *   *      *      *   *    *   *    *        *          *      *        *        *   * "
echo " *   *      *      *   *    *   *    *        *          *      *        *   *    *   * "
echo " *   *    *****     ***      ***     *****    *****      *      *****     ***     *   * "
echo "*************** OPEN MENU BY TYPING ${grn}./lempzy.sh${end} IN ROOT DIRECTORY ************************"
echo ""

exit
