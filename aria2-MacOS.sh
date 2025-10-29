#!/bin/bash

# --- Configuration ---
SERVICE_NAME="com.user.aria2rpc" # Custom service name
ARIA2_EXECUTABLE=$(which aria2c) # Find the path of the installed aria2c
ARIA2_DIR="$HOME/Library/Application Support/aria2" 
CONFIG_FILE="$ARIA2_DIR/aria2.conf"                
PLIST_FILE="$HOME/Library/LaunchAgents/$SERVICE_NAME.plist"
DOWNLOAD_DIR="$HOME/Downloads"
SESSION_FILE="$ARIA2_DIR/.aria2.session"           


# --- Checks ---
if [ ! -x "$ARIA2_EXECUTABLE" ]; then
    echo "❌ Error: aria2c executable not found. Check your Homebrew installation."
    exit 1
fi

# --- Stopping and Cleaning Up the Service ---
echo "🛑 Stopping and deleting the existing launchd service (if any)..."
launchctl unload -w "$PLIST_FILE" 2>/dev/null
rm -f "$PLIST_FILE" 2>/dev/null


# --- Creating the Configuration File (Error-free format) ---
echo "⚙️ Creating configuration file: $CONFIG_FILE"
mkdir -p "$ARIA2_DIR"
cat > "$CONFIG_FILE" << EOF
###############################
# Motrix macOS Aria2 config file
###############################
# RPC Settings
enable-rpc=true
rpc-allow-origin-all=true
rpc-listen-all=true
rpc-listen-port=6800

# File System and Download Settings
dir=$DOWNLOAD_DIR
auto-save-interval=10
disk-cache=64M
file-allocation=falloc
no-file-allocation-limit=64M
split=16
max-connection-per-server=8
save-session-interval=10
input-file=$SESSION_FILE
save-session=$SESSION_FILE

# Other Task Settings
bt-detach-seed-only=true
check-certificate=false
max-file-not-found=10
max-tries=0
retry-wait=10
connect-timeout=10
timeout=10
min-split-size=1M
http-accept-gzip=true
remote-time=true
summary-interval=0
content-disposition-default-utf8=true
user-agent=Mozilla/50 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15
bt-enable-lpd=true
bt-hash-check-seed=true
bt-max-peers=128
bt-prioritize-piece=head
bt-remove-unselected-file=true
bt-seed-unverified=false
bt-tracker-connect-timeout=10
bt-tracker-timeout=10
dht-entry-point=dht.transmissionbt.com:6881
dht-entry-point6=dht.transmissionbt.com:6881
enable-dht=true
enable-dht6=true
enable-peer-exchange=true
peer-agent=Transmission/3.00
peer-id-prefix=-TR3000-
EOF

# Create an empty session file
if [ ! -f "$SESSION_FILE" ]; then
    echo "" > "$SESSION_FILE"
fi

# --- Creating the Service Definition (Plist) ---
echo "⚙️ Creating launchd service file: $PLIST_FILE"
cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$ARIA2_EXECUTABLE</string>
        <string>--conf-path=$CONFIG_FILE</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>$ARIA2_DIR</string>
    <key>StandardErrorPath</key>
    <string>$ARIA2_DIR/error.log</string>
    <key>StandardOutPath</key>
    <string>$ARIA2_DIR/output.log</string>
</dict>
</plist>
EOF

# --- Loading and Starting the Service ---
echo "🚀 Loading and starting the service..."
launchctl load -w "$PLIST_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Aria2 service successfully installed and running in the background!"
    echo "-----------------------------------"
    echo "Service Status Check: **launchctl list | grep $SERVICE_NAME**"
    echo "Connection for Motrix: **http://localhost:6800**"
    echo "Error/Output Logs: $ARIA2_DIR/*.log"
else
    echo "❌ Error: Service could not be started with launchctl."
fi
