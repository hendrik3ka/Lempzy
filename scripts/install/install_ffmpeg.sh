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

# Install FFMPEG and IMAGEMAGICK
install_ffmpeg() {
     echo "${grn}Installing FFMPEG AND IMAGEMAGICK...${end}"
     echo ""
     sleep 3
     DEBIAN_FRONTEND=noninteractive apt-get install -y imagemagick -y
     DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg -y
     echo ""
     sleep 1
}

# Run
install_ffmpeg
