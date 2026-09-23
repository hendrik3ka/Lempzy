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
     OS_VER="$(. /etc/os-release; echo "${VERSION_ID}")"
     MAJOR="${OS_VER%%.*}"
     if command -v dnf >/dev/null 2>&1; then
          if ! dnf list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
               dnf install -y "oracle-epel-release-el${MAJOR}"
          fi
          dnf install -y ImageMagick || true
          dnf install -y ffmpeg || {
               echo "${yel}FFmpeg not available in current repositories${end}"
          }
     else
          if ! yum list installed "oracle-epel-release-el${MAJOR}" >/dev/null 2>&1; then
               yum install -y "oracle-epel-release-el${MAJOR}"
          fi
          yum install -y ImageMagick || true
          yum install -y ffmpeg || {
               echo "${yel}FFmpeg not available in current repositories${end}"
          }
     fi
     if command -v ffmpeg >/dev/null 2>&1; then
          echo "${grn}FFmpeg installed successfully${end}"
     else
          echo "${yel}FFmpeg not installed. Consider enabling a third-party repo that provides ffmpeg for Oracle Linux (e.g., RPM Fusion for EL).${end}"
     fi
     if command -v convert >/dev/null 2>&1; then
          echo "${grn}ImageMagick installed successfully${end}"
     else
          echo "${red}ImageMagick installation may have failed${end}"
     fi
     echo ""
     sleep 1
     command -v ffmpeg >/dev/null 2>&1 || return 1
}

# Run
install_ffmpeg
