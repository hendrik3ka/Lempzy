#!/bin/bash

# Telegram bot token and chat ID are read from environment variables.
# SECURITY: never hardcode credentials in scripts (they end up in git history).
# Set them before use, e.g. in /root/.bashrc or a systemd EnvironmentFile:
#   export TELEGRAM_BOT_TOKEN="123456:ABC-your-token"
#   export TELEGRAM_CHAT_ID="123456789"
# The previously committed token MUST be revoked via @BotFather (/revoke).
TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# Function to send a message
send_telegram_notification() {
  # Fail fast if credentials are not configured
  if [ -z "$TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "Error: TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID not set; notification skipped" >&2
    return 1
  fi
  MESSAGE_TEXT=$(echo "$1" | sed 's/\"/\\\"/g') # Escape quotes
  curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$MESSAGE_TEXT" \
    -d parse_mode="Markdown" > /dev/null  # Added Markdown support; errors to /dev/null
  if [ $? -ne 0 ]; then
    echo "Error: Failed to send Telegram notification" >&2  # Basic error handling
  fi
}

# Example usage (uncomment to test):
# send_telegram_notification "Hello from the monitoring script!"