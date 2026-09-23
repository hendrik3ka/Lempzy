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

# Install AB BENCHMARKING TOOL
install_ab() {
     echo "${grn}Installing AB BENCHMARKING TOOL ...${end}"
     echo ""
     sleep 3
     if command -v dnf >/dev/null 2>&1; then
          dnf install -y httpd-tools
     else
          yum install -y httpd-tools
     fi
     echo ""
     sleep 1
}

# Run
install_ab
