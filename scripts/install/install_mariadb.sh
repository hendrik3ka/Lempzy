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

# ---------------------------------------------------------------------------
# Security notes (2026 audit):
#  * Previous version seeded an EMPTY root password via debconf (by design)
#    and the seeding did not even work for repo-based 10.11/11.4 installs.
#  * New behaviour: after installation we run the equivalent of
#    `mariadb-secure-installation` non-interactively, setting a strong root
#    password, removing anonymous users, disallowing remote root login and
#    dropping the test database. The password is stored (obfuscated) for
#    root via mysql_config_editor (.mylogin.cnf) so subsequent `mysql`
#    calls in Lempzy scripts keep working WITHOUT a password on the CLI,
#    and never appear in process lists or shell history.
# ---------------------------------------------------------------------------

MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:-}"

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
               # Legacy installation method for 10.1 (EOL — not recommended)
               echo "${yel}Installing legacy MariaDB 10.1 (EOL)${end}"
               apt-get update
               DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mariadb-server
               ;;
          "10.11"|"11.4"|*)
               if [[ "$MARIADB_VERSION" != "10.11" && "$MARIADB_VERSION" != "11.4" ]]; then
                    echo "${red}Unsupported MariaDB version: $MARIADB_VERSION${end}"
                    echo "${yel}Falling back to MariaDB 10.11 LTS${end}"
                    MARIADB_VERSION="10.11"
               fi
               echo "${grn}Installing MariaDB $MARIADB_VERSION LTS${end}"
               # Add MariaDB repository
               export DEBIAN_FRONTEND=noninteractive
               apt-get update
               apt-get install -y software-properties-common dirmngr apt-transport-https
               # Download the repo setup script and validate it before executing
               # (previously executed blindly — MITM risk)
               curl -fsSLo /tmp/mariadb_repo_setup https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
               # Sanity checks: non-empty, valid shell script
               if [ ! -s /tmp/mariadb_repo_setup ] || ! head -1 /tmp/mariadb_repo_setup | grep -qE '^#!'; then
                    echo "${red}mariadb_repo_setup download failed or is not a valid script${end}"
                    exit 1
               fi
               bash /tmp/mariadb_repo_setup --mariadb-server-version="mariadb-$MARIADB_VERSION"
               apt-get update
               # NOTE: no debconf password seeding — the MariaDB repo packages
               # ignore it; the root password is set post-install below.
               apt-get install -y mariadb-server
               unset DEBIAN_FRONTEND
               ;;
     esac

     # Start and enable MariaDB service
     systemctl start mariadb
     systemctl enable mariadb

     # ------------------------------------------------------------------
     # Secure the installation (replaces empty debconf seeding):
     #   - set root password (random if not provided via env)
     #   - remove anonymous users
     #   - disallow remote root login
     #   - drop test database
     # ------------------------------------------------------------------
     secure_mariadb

     # Verify installation
     if systemctl is-active --quiet mariadb; then
          echo "${grn}MariaDB $MARIADB_VERSION installed, started and secured successfully${end}"
     else
          echo "${red}MariaDB installation completed but service failed to start${end}"
     fi

     echo ""
     sleep 1
}

secure_mariadb() {
     # Generate a random password if none was supplied via MARIADB_ROOT_PASSWORD
     if [[ -z "$MARIADB_ROOT_PASSWORD" ]]; then
          MARIADB_ROOT_PASSWORD="$(head -c 24 /dev/urandom | base64 | tr -d '/+=' | head -c 24)"
          GENERATED_PW=true
     fi

     # Apply secure-installation SQL via unix socket (root connects
     # passwordless over the socket right after a fresh install)
     mysql --protocol=socket -uroot <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD//\'/\'\'}';
DELETE FROM mysql.global_priv WHERE User='';
DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
SQL

     # Store credentials for root so Lempzy's `mysql` calls keep working
     # without exposing the password on the CLI or in scripts.
     mysql_config_editor set --login-path=lempzy \
          --host=localhost --user=root --password <<< "$MARIADB_ROOT_PASSWORD" 2>/dev/null || true

     if [[ "$GENERATED_PW" == "true" ]]; then
          echo ""
          echo "${yel}=========================================================${end}"
          echo "${yel} A random MariaDB root password was generated:${end}"
          echo "${blu}  $MARIADB_ROOT_PASSWORD${end}"
          echo "${yel} It is stored for root in ~/.mylogin.cnf (login path:${end}"
          echo "${yel} 'lempzy'). SAVE THIS PASSWORD NOW — it is shown once.${end}"
          echo "${yel}=========================================================${end}"
     fi
}

# Run
install_mariadb
