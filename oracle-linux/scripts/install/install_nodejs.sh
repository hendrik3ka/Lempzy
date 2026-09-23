#!/bin/bash
set -e
echo "${grn}Installing Node.js (latest)...${end}"
if command -v dnf >/dev/null 2>&1; then
    STREAM=$(dnf module list nodejs -q 2>/dev/null | grep -E '^\s*nodejs\s+[0-9]+' | awk '{print $2}' | sort -nr | head -1)
    dnf -y module reset nodejs >/dev/null 2>&1 || true
    if [ -n "$STREAM" ]; then
        dnf -y module enable nodejs:"$STREAM" >/dev/null 2>&1 || true
    fi
    dnf install -y nodejs npm || true
elif command -v yum >/dev/null 2>&1; then
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL https://rpm.nodesource.com/setup_current.x | bash - || curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
        yum install -y nodejs || true
    else
        yum install -y nodejs || true
    fi
else
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y nodejs npm || true
fi
if command -v node >/dev/null 2>&1; then
    echo "${grn}Node installed: $(node -v)${end}"
else
    echo "${yel}Node.js installation may have failed${end}"
fi
