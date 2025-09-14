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

# Install MariaDB server
install_mariadb() {
     # Use selected version or default to 10.11
     if [[ -n "$SELECTED_MARIADB_VERSION" ]]; then
          MARIADB_VERSION="$SELECTED_MARIADB_VERSION"
     else
          MARIADB_VERSION='10.11'  # Default to recommended LTS version
     fi
     
     echo "${grn}Installing MariaDB $MARIADB_VERSION...${end}"
     echo ""
     sleep 3
     
     # Install MariaDB based on version
     case $MARIADB_VERSION in
          "10.1")
               # Legacy installation method for 10.1
               echo "${yel}Installing legacy MariaDB 10.1 (EOL)${end}"
               debconf-set-selections <<<"maria-db-$MARIADB_VERSION mysql-server/root_password password $1"
               debconf-set-selections <<<"maria-db-$MARIADB_VERSION mysql-server/root_password_again password $1"
               apt-get install -qq mariadb-server
               ;;
          "10.11")
               # Install MariaDB 10.11 LTS
               echo "${grn}Installing MariaDB 10.11 LTS${end}"
               # Add MariaDB repository
               apt-get update
               apt-get install -y software-properties-common dirmngr apt-transport-https
               curl -o /tmp/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
               bash /tmp/mariadb_repo_setup --mariadb-server-version="mariadb-10.11"
               apt-get update
               # Set root password
               debconf-set-selections <<<"mariadb-server mysql-server/root_password password "
               debconf-set-selections <<<"mariadb-server mysql-server/root_password_again password "
               DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
               ;;
          "11.4")
               # Install MariaDB 11.4 LTS
               echo "${grn}Installing MariaDB 11.4 LTS${end}"
               # Add MariaDB repository
               apt-get update
               apt-get install -y software-properties-common dirmngr apt-transport-https
               curl -o /tmp/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
               bash /tmp/mariadb_repo_setup --mariadb-server-version="mariadb-11.4"
               apt-get update
               # Set root password
               debconf-set-selections <<<"mariadb-server mysql-server/root_password password "
               debconf-set-selections <<<"mariadb-server mysql-server/root_password_again password "
               DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
               ;;
          *)
               echo "${red}Unsupported MariaDB version: $MARIADB_VERSION${end}"
               echo "${yel}Falling back to MariaDB 10.11 LTS${end}"
               # Add MariaDB repository
               apt-get update
               apt-get install -y software-properties-common dirmngr apt-transport-https
               curl -o /tmp/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
               bash /tmp/mariadb_repo_setup --mariadb-server-version="mariadb-10.11"
               apt-get update
               # Set root password
               debconf-set-selections <<<"mariadb-server mysql-server/root_password password "
               debconf-set-selections <<<"mariadb-server mysql-server/root_password_again password "
               DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
               ;;
     esac
     
     # Start and enable MariaDB service
     systemctl start mariadb
     systemctl enable mariadb
     
     # Verify installation
     if systemctl is-active --quiet mariadb; then
          echo "${grn}MariaDB $MARIADB_VERSION installed and started successfully${end}"
     else
          echo "${red}MariaDB installation completed but service failed to start${end}"
     fi
     
     echo ""
     sleep 1
}

# Run
install_mariadb
