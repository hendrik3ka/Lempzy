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

# Get OS Version
OS_VERSION=$(lsb_release -rs)

# Update os
update_os() {
     echo "${grn}Starting update os ...${end}"
     echo ""
     sleep 3
     # Disable needrestart to avoid interactive prompts on supported Ubuntu versions.
     # The needrestart package may not be installed on some systems, so ignore errors.
     if [[ "${OS_VERSION}" == "22.04" ]] || [[ "${OS_VERSION}" == "22.10" ]] || [[ "${OS_VERSION}" == "24.04" ]]; then
          if [ -f /etc/needrestart/needrestart.conf ]; then
               sed -i 's/#$nrconf{restart} = '\''i'\'';/$nrconf{restart} = '\''a'\'';/' /etc/needrestart/needrestart.conf || true
               sudo apt -y remove needrestart || true
          fi
     fi

     # Always update the package list
     apt update

     # Use non‑interactive upgrades on recent Debian releases to avoid prompts.
     if [[ "${OS_VERSION}" == "11" ]] || [[ "${OS_VERSION}" == "12" ]] || [[ "${OS_VERSION}" == "13" ]]; then
          sudo DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade
     else
          apt upgrade -y
     fi

     echo ""
     sleep 1
}

# Run
update_os