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

update_os() {
     echo "${grn}Starting OS update ...${end}"
     echo ""
     sleep 3
     if command -v dnf >/dev/null 2>&1; then
          dnf -y update || true
          dnf -y upgrade || true
          dnf install -y policycoreutils-python-utils >/dev/null 2>&1 || dnf install -y policycoreutils-python >/dev/null 2>&1 || true
     elif command -v yum >/dev/null 2>&1; then
          yum -y update || true
          yum -y upgrade || true
          yum install -y policycoreutils-python >/dev/null 2>&1 || yum install -y policycoreutils-python-utils >/dev/null 2>&1 || true
     else
          apt update
          apt upgrade -y
     fi
     echo ""
     sleep 1
}

update_os
