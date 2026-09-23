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
     
     # Install MariaDB based on version (Oracle Linux / RHEL family)
     case $MARIADB_VERSION in
          "10.1")
               echo "${yel}Installing legacy MariaDB 10.1 (EOL)${end}"
               if command -v dnf >/dev/null 2>&1; then
                    dnf install -y mariadb-server
               else
                    yum install -y mariadb-server
               fi
               ;;
          "10.11")
               echo "${grn}Installing MariaDB 10.11 LTS${end}"
               curl -fsSL -o /tmp/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
               bash /tmp/mariadb_repo_setup --mariadb-server-version="mariadb-10.11"
               if command -v dnf >/dev/null 2>&1; then
                    dnf install -y MariaDB-server MariaDB-client
               else
                    yum install -y MariaDB-server MariaDB-client
               fi
               ;;
          "11.4")
               echo "${grn}Installing MariaDB 11.4 LTS${end}"
               curl -fsSL -o /tmp/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
               bash /tmp/mariadb_repo_setup --mariadb-server-version="mariadb-11.4"
               if command -v dnf >/dev/null 2>&1; then
                    dnf install -y MariaDB-server MariaDB-client
               else
                    yum install -y MariaDB-server MariaDB-client
               fi
               ;;
          *)
               echo "${red}Unsupported MariaDB version: $MARIADB_VERSION${end}"
               echo "${yel}Falling back to MariaDB 10.11 LTS${end}"
               curl -fsSL -o /tmp/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
               bash /tmp/mariadb_repo_setup --mariadb-server-version="mariadb-10.11"
               if command -v dnf >/dev/null 2>&1; then
                    dnf install -y MariaDB-server MariaDB-client
               else
                    yum install -y MariaDB-server MariaDB-client
               fi
               ;;
     esac
     
     # Start and enable MariaDB service
     systemctl start mariadb || systemctl start mysqld || true
     systemctl enable mariadb || systemctl enable mysqld || true
     
     # Verify installation
     if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysqld; then
          echo "${grn}MariaDB $MARIADB_VERSION installed and started successfully${end}"
     else
          echo "${red}MariaDB installation completed but service failed to start${end}"
     fi
     
     echo ""
     sleep 1
}

# Run
install_mariadb
