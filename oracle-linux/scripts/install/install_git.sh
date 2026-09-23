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

# Install Git And Curl
install_git() {
     echo "${grn}Installing Git And Curl ...${end}"
     echo ""
     sleep 3
     if command -v dnf >/dev/null 2>&1; then
          dnf install -y git curl
     else
          yum install -y git curl
     fi
     echo ""
     sleep 1
}

# Run
install_git
