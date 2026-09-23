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

# Install HTOP
install_htop() {
     echo "${grn}Installing HTOP ...${end}"
     echo ""
     sleep 3
     OS_VER="$(. /etc/os-release; echo "${VERSION_ID}")"
     MAJOR="${OS_VER%%.*}"
     if command -v dnf >/dev/null 2>&1; then
          if ! dnf list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
               dnf install -y "oracle-epel-release-el${MAJOR}"
          fi
          dnf install -y htop
     else
          if ! yum list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
               yum install -y "oracle-epel-release-el${MAJOR}"
          fi
          yum install -y htop
     fi
     echo ""
     sleep 1
}

# Run
install_htop
