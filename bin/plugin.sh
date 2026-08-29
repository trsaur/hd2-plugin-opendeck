#!/bin/bash

# Navigate to the directory where this script is located
cd "$(dirname "$0")"

# Parse the port and UUID from OpenDeck arguments
PORT=$(echo "$*" | grep -oP '\-port\s+\K[0-9]+')
UUID=$(echo "$*" | grep -oP '\-pluginUUID\s+\K[^\s]+')
LOG_FILE="./debug.log"

# Define the absolute path to the directory containing stratagem scripts
SCRIPTS_DIR="$(cd "$(dirname "$0")/../scripts" && pwd)"

# Verify that OpenDeck provided the required startup parameters
if [ -z "$PORT" ] || [ -z "$UUID" ]; then
  echo "[$(date)] Error: PORT or UUID arguments were not provided at startup" >> "$LOG_FILE"
  exit 1
fi

# =======================================================
# CRITICAL DELAY FOR STABLE OPENDECK BOOT
# The script sleeps in the background for 2.5 seconds.
# This gives the OpenDeck core enough time to safely query
# USB/HID devices and initialize the Ulanzi D200 driver.
# =======================================================
sleep 2.5

# Clear the old log file and write the initial startup log
echo "[$(date)] Logging initialized. Waiting for connection on port $PORT..." > "$LOG_FILE"

# 1. Connect to the OpenDeck TCP port
CONNECTED=false
for i in {1..30}; do
  if exec 3<>/dev/tcp/127.0.0.1/"$PORT" 2>/dev/null; then
    CONNECTED=true
    break
  fi
  sleep 0.1
done

if [ "$CONNECTED" = false ]; then
  echo "[$(date)] Error: Could not connect to port $PORT within 3 seconds" >> "$LOG_FILE"
  exit 1
fi

# 2. Perform the HTTP Handshake to upgrade the connection to WebSocket
printf "GET / HTTP/1.1\r\nHost: 127.0.0.1:$PORT\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n" >&3

# Give the OpenDeck web server a brief moment to transmit the response headers
sleep 0.2

# Dynamically read OpenDeck response headers until an empty line (\r) is reached
while read -r -t 1 line <&3; do
  line=$(echo "$line" | tr -d '\r')
  [ -z "$line" ] && break
done

# 3. Register the plugin within the OpenDeck environment (send UUID)
REG_JSON="{\"event\": \"registerPlugin\", \"uuid\": \"$UUID\"}"
MASKED_LEN=$(( ${#REG_JSON} | 128 ))
printf "\x81" >&3
printf "\\$(printf '%03o' "$MASKED_LEN")" >&3
printf "\x00\x00\x00\x00" >&3
printf "%s" "$REG_JSON" >&3

echo "[$(date)] Authorization successful. Listening for key events..." >> "$LOG_FILE"

# =======================================================
# 4. NON-BLOCKING STREAM DISPATCHER LOOP
# Split stream by '}' with a 0.05-second timeout.
# Does not block the main process or bottleneck the Ulanzi device.
# =======================================================
while true; do
  if read -r -d '}' -t 0.05 PACKET <&3; then
    
    PACKET="${PACKET}}"

    # Strictly filter for keyDown events belonging to our plugin namespace
    if [[ "$PACKET" =~ "keyDown" ]] && [[ "$BUFFER" =~ "com.user.helldivers2." || "$PACKET" =~ "com.user.helldivers2." ]]; then
      
      # Extract the macro script name directly from the isolated JSON block
      SCRIPT_NAME=$(echo "$PACKET" | sed -n 's/.*com\.user\.helldivers2\.\([^"'"'"']*\).*/\1/p' | tr -cd '[:print:]')

      echo "[DETECTED] KeyDown event captured! Extracted name: '$SCRIPT_NAME'" >> "$LOG_FILE"

      # Check for physical existence of the macro script file via its absolute path
      if [ -n "$SCRIPT_NAME" ] && [ -f "$SCRIPTS_DIR/$SCRIPT_NAME" ]; then
        echo "[START] Executing macro script: $SCRIPTS_DIR/$SCRIPT_NAME" >> "$LOG_FILE"
        
        # Launch the stratagem macro in the background, completely isolating it from fd &3
        "$SCRIPTS_DIR/$SCRIPT_NAME" </dev/null >/dev/null 2>&1 &
      else
        echo "[ERROR] Target file '$SCRIPTS_DIR/$SCRIPT_NAME' was not found!" >> "$LOG_FILE"
      fi
    fi
  else
    # If the socket is idle, verify if the OpenDeck host is still alive
    if ! true >&3 2>/dev/null; then
      echo "[$(date)] Connection was forcibly closed by OpenDeck. Exiting." >> "$LOG_FILE"
      exit 1
    fi
    # Sleep 20ms to prevent high CPU utilization during idle periods
    sleep 0.02
  fi
done
