# Firewall Configuration Guide

**Purpose:** Security configuration for n8n production deployment  
**When to use:** Setting up production security and network access controls  
**Prerequisites:** Administrative access to configure system firewall

## Overview

This guide provides firewall configuration recommendations for securing your n8n deployment in production environments.

## Firewall Principles for n8n

### Default Security Posture
- **Deny by Default**: Block all unnecessary ports and services
- **Least Privilege**: Only allow required network access
- **Regular Review**: Periodically audit and update rules
- **Logging**: Monitor and log firewall activity

### n8n Network Requirements
- **Web Interface**: Port 5678 (HTTP/HTTPS)
- **Webhooks**: Incoming connections for workflow triggers
- **Outbound API Calls**: HTTPS (443) for external service integration
- **Database**: PostgreSQL (5432) if using external database

## Platform-Specific Configuration

### macOS Firewall Setup

#### Enable macOS Firewall
```bash
# Enable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Set to stealth mode (don't respond to ping)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Allow signed applications
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setallowsigned on
```

#### Configure Application Access
```bash
# Allow Node.js (which runs n8n)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/node
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock /usr/local/bin/node

# Check status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

#### Advanced Configuration with pfctl
```bash
# Create pf configuration file
sudo tee /etc/pf.anchors/n8n << 'EOF'
# n8n Firewall Rules

# Allow loopback
pass on lo0

# Allow established connections
pass out keep state

# Allow SSH (if needed for remote management)
pass in proto tcp from any to any port 22

# Allow n8n web interface (restrict source if possible)
pass in proto tcp from any to any port 5678

# Allow HTTPS outbound for API calls
pass out proto tcp from any to any port 443

# Block everything else by default
block in all
EOF

# Load rules
sudo pfctl -f /etc/pf.anchors/n8n
sudo pfctl -e
```

### Linux (Ubuntu/Debian) UFW Setup

#### Install and Configure UFW
```bash
# Install UFW (if not installed)
sudo apt update
sudo apt install ufw

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (IMPORTANT: Do this first for remote access)
sudo ufw allow ssh

# Allow n8n web interface
sudo ufw allow 5678/tcp comment 'n8n web interface'

# Allow HTTPS outbound (usually allowed by default outgoing policy)
# sudo ufw allow out 443/tcp comment 'HTTPS outbound'

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

#### Restrict Access by IP (Recommended)
```bash
# Allow n8n only from specific IP ranges
sudo ufw delete allow 5678/tcp
sudo ufw allow from 192.168.1.0/24 to any port 5678 comment 'n8n from local network'
sudo ufw allow from 10.0.0.0/8 to any port 5678 comment 'n8n from private network'

# Or allow specific IPs only
sudo ufw allow from 203.0.113.100 to any port 5678 comment 'n8n from office IP'
```

### Linux (CentOS/RHEL) FirewallD Setup

#### Configure FirewallD
```bash
# Start and enable firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Set default zone
sudo firewall-cmd --set-default-zone=public

# Allow n8n service
sudo firewall-cmd --permanent --add-port=5678/tcp --zone=public
sudo firewall-cmd --permanent --add-service=https --zone=public

# Reload configuration
sudo firewall-cmd --reload

# Check status
sudo firewall-cmd --list-all
```

#### Create Custom Service Definition
```bash
# Create n8n service definition
sudo tee /etc/firewalld/services/n8n.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>n8n</short>
  <description>n8n workflow automation</description>
  <port protocol="tcp" port="5678"/>
</service>
EOF

# Reload and use custom service
sudo firewall-cmd --reload
sudo firewall-cmd --permanent --add-service=n8n --zone=public
sudo firewall-cmd --reload
```

## Network Security Best Practices

### VPN Access (Recommended for Production)
```bash
# Instead of exposing n8n directly, use VPN access
# 1. Set up VPN server (WireGuard, OpenVPN)
# 2. Only allow n8n access through VPN
sudo ufw delete allow 5678/tcp
sudo ufw allow in on wg0 to any port 5678 comment 'n8n via VPN only'
```

### Reverse Proxy with SSL Termination
```bash
# Use nginx/Apache as reverse proxy
# Allow only proxy access to n8n
sudo ufw delete allow 5678/tcp
sudo ufw allow 80/tcp comment 'HTTP redirect'
sudo ufw allow 443/tcp comment 'HTTPS'

# Configure n8n to only bind to localhost
# In .env: N8N_HOST=127.0.0.1
```

### Rate Limiting (Application Level)
Configure in nginx:
```nginx
http {
    limit_req_zone $binary_remote_addr zone=n8n:10m rate=10r/s;
    
    server {
        location / {
            limit_req zone=n8n burst=20 nodelay;
            proxy_pass http://127.0.0.1:5678;
        }
    }
}
```

## Monitoring and Alerting

### Firewall Log Monitoring

#### macOS Log Monitoring
```bash
# Monitor pfctl logs
sudo log stream --predicate 'subsystem == "com.apple.kernel.pflog"'

# Check for blocked connections
sudo log show --predicate 'subsystem == "com.apple.kernel.pflog"' --last 1h
```

#### Linux UFW Log Monitoring
```bash
# Enable UFW logging
sudo ufw logging on

# Monitor logs
sudo tail -f /var/log/ufw.log

# Parse blocked connections
sudo grep "UFW BLOCK" /var/log/ufw.log | tail -20
```

### Automated Monitoring Script
Create `scripts/monitor-firewall.sh`:
```bash
#!/bin/bash

# Firewall monitoring script
LOG_FILE="./logs/firewall-monitor.log"
mkdir -p ./logs

check_firewall_status() {
    echo "$(date): Checking firewall status" >> "$LOG_FILE"
    
    # Check based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        STATUS=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)
        echo "$(date): macOS Firewall - $STATUS" >> "$LOG_FILE"
    elif command -v ufw >/dev/null 2>&1; then
        # Ubuntu/Debian
        STATUS=$(sudo ufw status | head -1)
        echo "$(date): UFW - $STATUS" >> "$LOG_FILE"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        # CentOS/RHEL
        STATUS=$(sudo firewall-cmd --state)
        echo "$(date): FirewallD - $STATUS" >> "$LOG_FILE"
    fi
}

check_suspicious_connections() {
    echo "$(date): Checking for suspicious connections to port 5678" >> "$LOG_FILE"
    
    # Check current connections
    CONNECTIONS=$(netstat -an | grep ":5678" | wc -l)
    echo "$(date): Active connections to n8n: $CONNECTIONS" >> "$LOG_FILE"
    
    if [ "$CONNECTIONS" -gt 10 ]; then
        echo "$(date): WARNING - High number of connections to n8n: $CONNECTIONS" >> "$LOG_FILE"
    fi
}

# Run checks
check_firewall_status
check_suspicious_connections
```

## Emergency Procedures

### Lockdown Mode
```bash
#!/bin/bash
# Emergency lockdown script

echo "🚨 EMERGENCY LOCKDOWN ACTIVATED"

# Stop n8n
pkill -f "n8n" || true

# Block all incoming except SSH
if command -v ufw >/dev/null 2>&1; then
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw --force enable
elif command -v firewall-cmd >/dev/null 2>&1; then
    sudo firewall-cmd --panic-on
fi

echo "✅ Lockdown complete - only SSH allowed"
echo "📝 Check logs and restore services manually"
```

### Service Restoration
```bash
#!/bin/bash
# Restore normal firewall rules

echo "🔄 Restoring normal firewall configuration"

if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 5678/tcp comment 'n8n web interface'
    sudo ufw reload
elif command -v firewall-cmd >/dev/null 2>&1; then
    sudo firewall-cmd --panic-off
    sudo firewall-cmd --permanent --add-port=5678/tcp
    sudo firewall-cmd --reload
fi

# Restart n8n
./start-n8n.sh

echo "✅ Services restored"
```

## Validation and Testing

### Firewall Rule Testing
```bash
#!/bin/bash
# Test firewall configuration

echo "🔍 Testing firewall configuration"

# Test external access
echo "Testing external access to n8n..."
timeout 5 curl -I http://your-server-ip:5678 2>/dev/null && echo "✅ n8n accessible" || echo "❌ n8n blocked"

# Test blocked ports
echo "Testing blocked ports..."
timeout 5 nc -zv your-server-ip 3306 2>/dev/null && echo "❌ MySQL accessible (should be blocked)" || echo "✅ MySQL properly blocked"

# Test outbound connectivity
echo "Testing outbound connectivity..."
curl -I https://api.github.com 2>/dev/null && echo "✅ Outbound HTTPS working" || echo "❌ Outbound HTTPS blocked"

echo "🎉 Firewall testing complete"
```

### Security Audit Script
```bash
#!/bin/bash
# Security audit for n8n deployment

echo "🔐 n8n Security Audit"
echo "==================="

# Check firewall status
echo "Firewall Status:"
if command -v ufw >/dev/null 2>&1; then
    sudo ufw status
elif command -v firewall-cmd >/dev/null 2>&1; then
    sudo firewall-cmd --list-all
fi

# Check listening ports
echo -e "\nListening Ports:"
netstat -tuln | grep LISTEN

# Check n8n process
echo -e "\nn8n Process:"
ps aux | grep n8n | grep -v grep

# Check for suspicious connections
echo -e "\nActive Connections to n8n:"
netstat -an | grep ":5678"

echo -e "\n🎉 Security audit complete"
```

This firewall configuration guide provides comprehensive security setup for n8n production deployments across different platforms and scenarios.