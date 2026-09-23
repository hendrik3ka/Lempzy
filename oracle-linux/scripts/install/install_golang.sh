#!/bin/bash
set -e
echo "${grn}Installing Go (go-toolset)...${end}"
if command -v dnf >/dev/null 2>&1; then
    dnf install -y go-toolset || true
elif command -v yum >/dev/null 2>&1; then
    yum install -y go-toolset || true
else
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y golang || true
fi
if command -v go >/dev/null 2>&1; then
    echo "${grn}Go installed: $(go version)${end}"
else
    echo "${yel}Go installation may have failed${end}"
fi
