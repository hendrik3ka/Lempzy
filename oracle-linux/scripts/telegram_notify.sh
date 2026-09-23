#!/bin/bash

# Your Telegram bot token and chat ID
TOKEN="6380344944:AAHpptO_U1hzwiS6sSzgTu8pUG07KmfAg1M"
CHAT_ID="366284934"  # Replace with your real chat ID

# Function to send a message
send_telegram_notification() {
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