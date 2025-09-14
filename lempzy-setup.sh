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
     cd && cd && cd Lempzy
else
     echo "Cannot Update OS"
     exit
fi

# Installing UFW Firewall
INSTALL_UFW_FIREWALL=scripts/install/install_firewall.sh

if test -f "$INSTALL_UFW_FIREWALL"; then
     source $INSTALL_UFW_FIREWALL
     cd && cd Lempzy
else
     echo "${red}Cannot Install UFW Firewall${end}"
     exit
fi

# Install MariaDB
INSTALL_MARIADB=scripts/install/install_mariadb.sh

if test -f "$INSTALL_MARIADB"; then
     source $INSTALL_MARIADB
     cd && cd Lempzy
else
     echo "${red}Cannot Install MariaDB${end}"
     exit
fi

# Install PHP And Configure PHP
echo "${grn}=== PHP VERSION SELECTION ===${end}"
echo "${yel}Choose your preferred PHP version:${end}"
echo "${blu}1) PHP 7.4${end}"
echo "${blu}2) PHP 8.0${end}"
echo "${blu}3) PHP 8.1${end}"
echo "${blu}4) PHP 8.2${end}"
echo "${blu}5) PHP 8.3${end}"
echo "${blu}6) Auto-detect based on OS (default behavior)${end}"
echo ""
read -p "${cyn}Enter your choice (1-6): ${end}" php_choice

# Set PHP version based on user choice
case $php_choice in
    1)
        SELECTED_PHP_VERSION="7.4"
        echo "${grn}Selected PHP 7.4${end}"
        ;;
    2)
        SELECTED_PHP_VERSION="8.0"
        echo "${grn}Selected PHP 8.0${end}"
        ;;
    3)
        SELECTED_PHP_VERSION="8.1"
        echo "${grn}Selected PHP 8.1${end}"
        ;;
    4)
        SELECTED_PHP_VERSION="8.2"
        echo "${grn}Selected PHP 8.2${end}"
        ;;
    5)
        SELECTED_PHP_VERSION="8.3"
        echo "${grn}Selected PHP 8.3${end}"
        ;;
    6|"")
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
        cd "$(dirname "$0")"
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
     cd && cd Lempzy
else
     echo "${red}Cannot Install Nginx${end}"
     exit
fi

# Install Caching Solution (Memcached/Redis)
echo "${grn}=== CACHING SOLUTION SELECTION ===${end}"
echo "${yel}Choose your preferred caching solution:${end}"
echo "${blu}1) Install Memcached only${end}"
echo "${blu}2) Install Redis only${end}"
echo "${blu}3) Install both Memcached and Redis${end}"
echo "${blu}4) Skip caching installation${end}"
echo ""
read -p "${cyn}Enter your choice (1-4): ${end}" cache_choice

case $cache_choice in
    1)
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
                cd "$(dirname "$0")"
            else
                echo "${red}Cannot find Memcached installation script${end}"
                add_failed_installation "Memcached (script not found)"
            fi
        fi
        ;;
    2)
        echo "${grn}Installing Redis...${end}"
        INSTALL_REDIS=scripts/install/install_redis.sh
        
        # Check if redis is already installed
        if check_command_exists "redis-server" || check_package_installed "redis-server"; then
            echo "${grn}Redis is already installed, skipping...${end}"
        else
            if test -f "$INSTALL_REDIS"; then
                if source "$INSTALL_REDIS"; then
                    echo "${grn}Redis installed successfully${end}"
                else
                    add_failed_installation "Redis"
                fi
                cd "$(dirname "$0")"
            else
                echo "${red}Cannot find Redis installation script${end}"
                add_failed_installation "Redis (script not found)"
            fi
        fi
        ;;
    3)
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
                cd "$(dirname "$0")"
            else
                echo "${red}Cannot find Memcached installation script${end}"
                add_failed_installation "Memcached (script not found)"
            fi
        fi
        
        # Install Redis
        INSTALL_REDIS=scripts/install/install_redis.sh
        if check_command_exists "redis-server" || check_package_installed "redis-server"; then
            echo "${grn}Redis is already installed, skipping...${end}"
        else
            if test -f "$INSTALL_REDIS"; then
                echo "${grn}Installing Redis...${end}"
                if source "$INSTALL_REDIS"; then
                    echo "${grn}Redis installed successfully${end}"
                else
                    add_failed_installation "Redis"
                fi
                cd "$(dirname "$0")"
            else
                echo "${red}Cannot find Redis installation script${end}"
                add_failed_installation "Redis (script not found)"
            fi
        fi
        ;;
    4)
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
        cd "$(dirname "$0")"
    else
        echo "${red}Cannot find Ioncube installation script${end}"
        add_failed_installation "Ioncube (script not found)"
    fi
fi

# Install Mcrypt
INSTALL_MCRPYT=scripts/install/install_mcrypt.sh

# Check if mcrypt is already installed (check for mcrypt extension in PHP)
if php -m 2>/dev/null | grep -q "mcrypt" || check_package_installed "php.*-mcrypt"; then
    echo "${grn}Mcrypt is already installed, skipping...${end}"
else
    if test -f "$INSTALL_MCRPYT"; then
        echo "${grn}Installing Mcrypt...${end}"
        if source "$INSTALL_MCRPYT"; then
            echo "${grn}Mcrypt installed successfully${end}"
        else
            add_failed_installation "Mcrypt"
        fi
        # Return to the script directory
        cd "$(dirname "$0")"
    else
        echo "${red}Cannot find Mcrypt installation script${end}"
        add_failed_installation "Mcrypt (script not found)"
    fi
fi

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
        cd "$(dirname "$0")"
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
        cd "$(dirname "$0")"
    else
        echo "${red}Cannot find Netstat installation script${end}"
        add_failed_installation "Netstat (script not found)"
    fi
fi

# Install OpenSSL
INSTALL_OPENSSL=scripts/install/install_openssl.sh

# Check if openssl is already installed
if check_command_exists "openssl" || check_package_installed "openssl"; then
    echo "${grn}OpenSSL is already installed, skipping...${end}"
else
    if test -f "$INSTALL_OPENSSL"; then
        echo "${grn}Installing OpenSSL...${end}"
        if source "$INSTALL_OPENSSL"; then
            echo "${grn}OpenSSL installed successfully${end}"
        else
            add_failed_installation "OpenSSL"
        fi
        # Return to the script directory
        cd "$(dirname "$0")"
    else
        echo "${red}Cannot find OpenSSL installation script${end}"
        add_failed_installation "OpenSSL (script not found)"
    fi
fi

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
        cd "$(dirname "$0")"
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
        cd "$(dirname "$0")"
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
        cd "$(dirname "$0")"
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
        cd "$(dirname "$0")"
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
        cd "$(dirname "$0")"
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
    # Return to the script directory
    cd "$(dirname "$0")"
    sleep 1
}

change_login_greetings

# Menu Script Permission Setting
# Ensure we're in the correct directory
SCRIPT_DIR="$(dirname "$0")"
cd "$SCRIPT_DIR"

# Check if lempzy.sh exists and copy it
if [ -f "scripts/lempzy.sh" ]; then
    cp scripts/lempzy.sh /root
    dos2unix /root/lempzy.sh
    chmod +x /root/lempzy.sh
    echo "${grn}Menu script installed successfully${end}"
else
    echo "${red}Warning: scripts/lempzy.sh not found, menu script not installed${end}"
    add_failed_installation "Menu Script (lempzy.sh not found)"
fi

# Success Prompt
clear
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
