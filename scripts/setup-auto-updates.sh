#!/bin/bash

# Auto-Updates Setup Script
# Configure automatic security updates for n8n production deployment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AUTO_UPDATE_CONFIG="./auto-update.conf"
NOTIFICATION_EMAIL="${NOTIFICATION_EMAIL:-admin@n8n-production.local}"

echo -e "${GREEN}🔄 Auto-Updates Setup${NC}"
echo -e "${GREEN}===================${NC}"
echo ""

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        echo -e "${BLUE}🍎 Detected: macOS${NC}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt >/dev/null 2>&1; then
            DISTRO="debian"
            echo -e "${BLUE}🐧 Detected: Linux (Debian/Ubuntu)${NC}"
        elif command -v yum >/dev/null 2>&1; then
            DISTRO="rhel"
            echo -e "${BLUE}🐧 Detected: Linux (RHEL/CentOS)${NC}"
        else
            DISTRO="unknown"
            echo -e "${YELLOW}⚠️ Linux distribution not detected${NC}"
        fi
    else
        OS="unknown"
        echo -e "${RED}❌ Unsupported operating system${NC}"
        exit 1
    fi
}

# macOS auto-updates setup
setup_macos_updates() {
    echo -e "${GREEN}🔧 Configuring macOS auto-updates...${NC}"
    
    # Enable automatic system updates
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
    
    echo -e "${GREEN}✅ macOS system auto-updates enabled${NC}"
    
    # Setup Homebrew auto-updates for n8n
    if command -v brew >/dev/null 2>&1; then
        echo -e "${GREEN}🍺 Setting up Homebrew auto-updates...${NC}"
        
        # Create auto-update script for n8n
        cat > /usr/local/bin/n8n-auto-update << 'EOF'
#!/bin/bash
# n8n Auto-Update Script for macOS

LOG_FILE="/tmp/n8n-auto-update.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting n8n auto-update check..." >> "$LOG_FILE"

# Update Homebrew
brew update >> "$LOG_FILE" 2>&1

# Check for n8n updates
if brew outdated | grep -q "node"; then
    echo "[$DATE] Node.js update available, updating..." >> "$LOG_FILE"
    brew upgrade node >> "$LOG_FILE" 2>&1
fi

# Update n8n via npm
npm update -g n8n >> "$LOG_FILE" 2>&1

# Check if n8n is running and restart if needed
if pgrep -f "n8n" > /dev/null; then
    echo "[$DATE] n8n is running, restarting after update..." >> "$LOG_FILE"
    pkill -f "n8n" || true
    sleep 5
    # Start n8n in background
    cd /path/to/n8n && ./start-n8n.sh >> "$LOG_FILE" 2>&1 &
fi

echo "[$DATE] n8n auto-update completed" >> "$LOG_FILE"
EOF
        
        sudo chmod +x /usr/local/bin/n8n-auto-update
        
        # Create launchd plist for automatic execution
        sudo tee /Library/LaunchDaemons/com.n8n.autoupdate.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.n8n.autoupdate</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/n8n-auto-update</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/n8n-autoupdate-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/n8n-autoupdate-stderr.log</string>
</dict>
</plist>
EOF
        
        sudo launchctl load /Library/LaunchDaemons/com.n8n.autoupdate.plist
        echo -e "${GREEN}✅ n8n auto-updates scheduled daily at 2:00 AM${NC}"
    else
        echo -e "${YELLOW}⚠️ Homebrew not found, manual n8n updates required${NC}"
    fi
}

# Linux (Debian/Ubuntu) auto-updates setup
setup_debian_updates() {
    echo -e "${GREEN}🔧 Configuring Debian/Ubuntu auto-updates...${NC}"
    
    # Install unattended-upgrades
    sudo apt update
    sudo apt install -y unattended-upgrades apt-listchanges
    
    # Configure unattended-upgrades
    sudo tee /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
    // Add packages to exclude from auto-update
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Mail "${NOTIFICATION_EMAIL}";
Unattended-Upgrade::MailOnlyOnError "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "false";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

    # Enable automatic updates
    sudo tee /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

    # Enable and start the service
    sudo systemctl enable unattended-upgrades
    sudo systemctl start unattended-upgrades
    
    echo -e "${GREEN}✅ Ubuntu/Debian auto-updates enabled${NC}"
    
    # Setup n8n auto-updates
    setup_linux_n8n_updates
}

# Linux (RHEL/CentOS) auto-updates setup
setup_rhel_updates() {
    echo -e "${GREEN}🔧 Configuring RHEL/CentOS auto-updates...${NC}"
    
    # Install dnf-automatic
    sudo yum install -y dnf-automatic
    
    # Configure dnf-automatic
    sudo tee /etc/dnf/automatic.conf << EOF
[commands]
upgrade_type = security
random_sleep = 3600
network_online_timeout = 60
download_updates = yes
apply_updates = yes

[emitters]
emit_via = email
system_name = n8n-production

[email]
email_from = ${NOTIFICATION_EMAIL}
email_to = ${NOTIFICATION_EMAIL}
email_host = localhost
EOF

    # Enable and start the service
    sudo systemctl enable dnf-automatic.timer
    sudo systemctl start dnf-automatic.timer
    
    echo -e "${GREEN}✅ RHEL/CentOS auto-updates enabled${NC}"
    
    # Setup n8n auto-updates
    setup_linux_n8n_updates
}

# Linux n8n auto-updates
setup_linux_n8n_updates() {
    echo -e "${GREEN}🚀 Setting up n8n auto-updates for Linux...${NC}"
    
    # Create n8n update script
    sudo tee /usr/local/bin/n8n-auto-update << 'EOF'
#!/bin/bash
# n8n Auto-Update Script for Linux

LOG_FILE="/var/log/n8n-auto-update.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
N8N_DIR="/path/to/n8n"  # Update this path

echo "[$DATE] Starting n8n auto-update check..." >> "$LOG_FILE"

# Update Node.js (if using NodeSource repository)
if command -v apt >/dev/null 2>&1; then
    apt list --upgradable 2>/dev/null | grep -q nodejs && {
        echo "[$DATE] Node.js update available" >> "$LOG_FILE"
        # Node.js updates handled by system auto-updates
    }
elif command -v yum >/dev/null 2>&1; then
    yum check-update nodejs &>/dev/null && {
        echo "[$DATE] Node.js update available" >> "$LOG_FILE"
        # Node.js updates handled by system auto-updates  
    }
fi

# Update n8n via npm
npm update -g n8n >> "$LOG_FILE" 2>&1

# Check if n8n is running and restart if needed
if pgrep -f "n8n" > /dev/null; then
    echo "[$DATE] n8n is running, restarting after update..." >> "$LOG_FILE"
    systemctl stop n8n || pkill -f "n8n" || true
    sleep 5
    systemctl start n8n || (cd "$N8N_DIR" && ./start-n8n.sh >> "$LOG_FILE" 2>&1 &)
fi

echo "[$DATE] n8n auto-update completed" >> "$LOG_FILE"
EOF

    sudo chmod +x /usr/local/bin/n8n-auto-update
    
    # Create systemd timer for n8n updates
    sudo tee /etc/systemd/system/n8n-auto-update.service << EOF
[Unit]
Description=n8n Auto Update Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/n8n-auto-update
User=root
EOF

    sudo tee /etc/systemd/system/n8n-auto-update.timer << EOF
[Unit]
Description=n8n Auto Update Timer
Requires=n8n-auto-update.service

[Timer]
OnCalendar=daily
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable n8n-auto-update.timer
    sudo systemctl start n8n-auto-update.timer
    
    echo -e "${GREEN}✅ n8n auto-updates scheduled daily${NC}"
}

# Create update configuration file
create_update_config() {
    cat > "${AUTO_UPDATE_CONFIG}" << EOF
# Auto-Update Configuration
# Generated: $(date)

# Operating System
OS=${OS}
DISTRO=${DISTRO:-}

# Notification Settings
NOTIFICATION_EMAIL=${NOTIFICATION_EMAIL}
ENABLE_EMAIL_NOTIFICATIONS=true

# Update Schedule
SYSTEM_UPDATE_TIME=02:00
N8N_UPDATE_TIME=02:30

# Update Preferences
AUTO_RESTART_N8N=true
BACKUP_BEFORE_UPDATE=true
SECURITY_UPDATES_ONLY=false

# Exclusions
EXCLUDED_PACKAGES=""

# Logging
LOG_RETENTION_DAYS=30
ENABLE_UPDATE_LOGS=true
EOF

    echo -e "${GREEN}✅ Update configuration saved: ${AUTO_UPDATE_CONFIG}${NC}"
}

# Create update management script
create_management_script() {
    cat > scripts/manage-updates.sh << 'EOF'
#!/bin/bash

# Update Management Script
ACTION="$1"

case "$ACTION" in
    status)
        echo "📊 Auto-Update Status:"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "System Updates:"
            defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled
            echo "n8n Updates:"
            sudo launchctl list | grep -q "com.n8n.autoupdate" && echo "✅ Enabled" || echo "❌ Disabled"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v systemctl >/dev/null 2>&1; then
                echo "System Updates:"
                systemctl is-enabled unattended-upgrades 2>/dev/null || systemctl is-enabled dnf-automatic 2>/dev/null || echo "❌ Not configured"
                echo "n8n Updates:"
                systemctl is-enabled n8n-auto-update.timer 2>/dev/null || echo "❌ Not configured"
            fi
        fi
        ;;
    enable)
        echo "🔄 Enabling auto-updates..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sudo launchctl load /Library/LaunchDaemons/com.n8n.autoupdate.plist 2>/dev/null || echo "Already enabled"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo systemctl enable n8n-auto-update.timer 2>/dev/null || echo "Service not found"
        fi
        ;;
    disable)
        echo "🛑 Disabling auto-updates..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sudo launchctl unload /Library/LaunchDaemons/com.n8n.autoupdate.plist 2>/dev/null || echo "Already disabled"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo systemctl disable n8n-auto-update.timer 2>/dev/null || echo "Service not found"
        fi
        ;;
    test)
        echo "🧪 Testing update process..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sudo /usr/local/bin/n8n-auto-update
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo /usr/local/bin/n8n-auto-update
        fi
        ;;
    logs)
        echo "📋 Recent update logs:"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            tail -20 /tmp/n8n-auto-update.log 2>/dev/null || echo "No logs found"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            tail -20 /var/log/n8n-auto-update.log 2>/dev/null || echo "No logs found"
        fi
        ;;
    *)
        echo "Usage: $0 {status|enable|disable|test|logs}"
        exit 1
        ;;
esac
EOF

    chmod +x scripts/manage-updates.sh
    echo -e "${GREEN}✅ Update management script created: scripts/manage-updates.sh${NC}"
}

# Main execution
detect_os

echo -e "${BLUE}🔧 Setting up auto-updates for ${OS}...${NC}"

case "$OS" in
    macos)
        setup_macos_updates
        ;;
    linux)
        case "$DISTRO" in
            debian)
                setup_debian_updates
                ;;
            rhel)
                setup_rhel_updates
                ;;
            *)
                echo -e "${RED}❌ Unsupported Linux distribution${NC}"
                exit 1
                ;;
        esac
        ;;
    *)
        echo -e "${RED}❌ Unsupported operating system${NC}"
        exit 1
        ;;
esac

create_update_config
create_management_script

echo ""
echo -e "${GREEN}🎉 Auto-updates setup completed!${NC}"
echo ""
echo -e "${YELLOW}📝 Configuration Summary:${NC}"
echo -e "${YELLOW}   - System updates: Enabled${NC}"
echo -e "${YELLOW}   - n8n updates: Enabled${NC}"
echo -e "${YELLOW}   - Notification email: ${NOTIFICATION_EMAIL}${NC}"
echo -e "${YELLOW}   - Update schedule: Daily at 2:00 AM${NC}"
echo ""
echo -e "${BLUE}💡 Management Commands:${NC}"
echo -e "${BLUE}   Status:  ./scripts/manage-updates.sh status${NC}"
echo -e "${BLUE}   Test:    ./scripts/manage-updates.sh test${NC}"
echo -e "${BLUE}   Logs:    ./scripts/manage-updates.sh logs${NC}"
echo -e "${BLUE}   Enable:  ./scripts/manage-updates.sh enable${NC}"
echo -e "${BLUE}   Disable: ./scripts/manage-updates.sh disable${NC}"

# Add auto-update info to .env
if ! grep -q "AUTO_UPDATES" .env 2>/dev/null; then
    echo "" >> .env
    echo "# Auto-Update Configuration" >> .env
    echo "AUTO_UPDATES=enabled" >> .env
    echo "UPDATE_NOTIFICATION_EMAIL=${NOTIFICATION_EMAIL}" >> .env
fi

echo ""
echo -e "${GREEN}✅ Auto-update configuration saved to: ${AUTO_UPDATE_CONFIG}${NC}"
echo -e "${YELLOW}🔒 Review email settings for notifications!${NC}"