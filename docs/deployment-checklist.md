# n8n Production Deployment Checklist

**Purpose**: Complete setup and maintenance guide for 90% self-hosting best practices coverage  
**Target Audience**: System administrators deploying production n8n  
**Last Updated**: 2025-06-29

## 🚀 **One-Time Setup (Required)**

### **Initial Deployment (15 minutes)**

#### **Step 1: Deploy 24/7 Monitoring**
```bash
./scripts/setup-monitoring.sh
```
**Choose**: Option 1 (basic) or Option 2 (full stack - recommended)

**Results**:
- Uptime Kuma deployed at http://localhost:3001
- Health checks for n8n service
- Management scripts available

#### **Step 2: Configure Auto-Updates**
```bash
./scripts/setup-auto-updates.sh
```
**What happens**:
- OS detection (macOS/Linux)
- System security updates enabled
- n8n application updates scheduled
- Daily updates at 2:00 AM configured

#### **Step 3: Set Up Encrypted Backups**
```bash
./scripts/backup-n8n-encrypted.sh
```
**Results**:
- GPG key generated automatically
- First encrypted backup created
- Backup procedures established

#### **Step 4: Configure Monitoring Dashboard**
1. Open http://localhost:3001
2. Create admin account (first time only)
3. Add monitors:
   - **n8n Service**: http://localhost:5678
   - **System Health**: Heartbeat monitors
4. Configure email/webhook notifications

### **Security Configuration (10 minutes)**

#### **Email Notifications**
```bash
# Set your notification email
export NOTIFICATION_EMAIL="admin@yourdomain.com"
# Re-run setup scripts to apply
```

#### **GPG Key Backup (Critical)**
```bash
# After first backup, save your GPG key
gpg --list-secret-keys --keyid-format LONG
# Note the KEY_ID, then:
gpg --export-secret-key KEY_ID > gpg-private-key.asc
```
**⚠️ CRITICAL**: Store `gpg-private-key.asc` securely offline!

#### **Password Management**
Check generated passwords in:
- `monitoring.env` - Grafana/Redis passwords
- `.env` - n8n authentication
- **Action**: Save all passwords in secure password manager

### **Optional Enhancements**

#### **PostgreSQL Migration**
```bash
# For production scale (optional)
# Follow: docs/postgresql-migration.md
```

#### **Firewall Configuration**
```bash
# Platform-specific security
# Follow: docs/firewall-setup.md
```

#### **HTTPS Setup**
```bash
./scripts/setup-https.sh
```

## 🔄 **Startup Procedures**

### **Every Time n8n Starts**

#### **Automatic (Configured by setup)**
- Health checks begin monitoring
- Backup retention cleanup
- Service availability tracking

#### **Manual Verification (Recommended)**
```bash
# Check all systems operational
./scripts/manage-monitoring.sh status
./scripts/manage-updates.sh status

# Verify n8n accessibility
curl -I http://localhost:5678
```

### **After System Reboot**
```bash
# Restart monitoring stack if needed
./scripts/manage-monitoring.sh start

# Verify n8n auto-started
ps aux | grep n8n
```

## 📅 **Daily Operations**

### **Automated (No Action Required)**
- ✅ **Auto-Updates**: System and n8n updates at 2:00 AM
- ✅ **Monitoring**: 24/7 service health tracking
- ✅ **Backup Cleanup**: Old backups automatically removed (7+ days)

### **Recommended Daily Checks (2 minutes)**
```bash
# Morning health check
./scripts/manage-monitoring.sh status

# Check for any overnight issues
./scripts/manage-updates.sh logs | tail -20

# Verify backup directory
ls -la backups/ | tail -5
```

### **Daily Monitoring Dashboard**
- Check Uptime Kuma: http://localhost:3001
- Review any alert notifications
- Verify service uptime metrics

## 🗓️ **Weekly Maintenance (5 minutes)**

### **Security Review**
```bash
# Run security audit
# Check docs/production-hardening.md for audit script

# Review access logs
grep "login\|auth" n8n-data/logs/n8n.log | tail -20

# Verify firewall status
./scripts/manage-monitoring.sh status
```

### **Backup Verification**
```bash
# Create test backup
./scripts/backup-n8n-encrypted.sh

# Verify backup integrity
ls -la backups/ | grep $(date +%Y%m%d)

# Test GPG decryption (optional)
# gpg --decrypt latest-backup.tar.gz.gpg | tar -tzf - > /dev/null
```

### **Performance Check**
```bash
# Monitor resource usage
ps aux | grep n8n
df -h  # Disk space
free -h  # Memory usage (Linux)
```

## 📆 **Monthly Operations (15 minutes)**

### **Security Updates Review**
```bash
# Check update history
./scripts/manage-updates.sh logs

# Review auto-update configuration
cat auto-update.conf

# Verify no pending security patches
# macOS: softwareupdate -l
# Linux: apt list --upgradable | grep -i security
```

### **Backup Strategy Review**
```bash
# Backup size trends
du -sh backups/*/
find backups/ -name "*.tar.gz.gpg" -exec ls -lh {} \; | tail -10

# Test restore procedure (recommended)
# Follow backup_info.txt instructions from recent backup
```

### **Monitoring Configuration**
- Review alert thresholds in Uptime Kuma
- Update notification contacts if needed
- Check monitoring data retention

### **Performance Optimization**
```bash
# Database maintenance (if using PostgreSQL)
# See docs/postgresql-migration.md

# Log rotation check
find n8n-data/logs/ -name "*.log" -size +100M

# Monitor disk usage trends
```

## 🆘 **Troubleshooting Quick Reference**

### **Service Issues**
```bash
# n8n not responding
./start-n8n.sh
curl -I http://localhost:5678

# Monitoring down
./scripts/manage-monitoring.sh restart

# Check logs
tail -f n8n-data/logs/n8n.log
```

### **Backup Issues**
```bash
# GPG key problems
gpg --list-secret-keys
gpg --generate-key  # If no keys found

# Backup failures
./scripts/backup-n8n-encrypted.sh
# Check error messages and disk space
```

### **Update Issues**
```bash
# Auto-updates not working
./scripts/manage-updates.sh status
./scripts/manage-updates.sh test

# Manual update
npm update -g n8n
```

## 📊 **Health Check Commands**

### **System Status Overview**
```bash
echo "=== n8n Production Health Check ==="
echo "n8n Service: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678)"
echo "Monitoring: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001)"
echo "Disk Usage: $(df -h / | tail -1 | awk '{print $5}')"
echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "Last Backup: $(ls -t backups/*.tar.gz.gpg 2>/dev/null | head -1 | xargs basename)"
echo "Auto-Updates: $(./scripts/manage-updates.sh status | grep -o 'Enabled\|Disabled')"
```

### **Security Validation**
```bash
# Verify encryption
file backups/*.tar.gz.gpg | head -3

# Check authentication
grep "N8N_BASIC_AUTH_ACTIVE=true" .env

# Firewall status
# macOS: sudo pfctl -sr | grep 5678
# Linux: sudo ufw status | grep 5678
```

## 📚 **Documentation Reference**

### **Detailed Guides**
- **Production Hardening**: `docs/production-hardening.md` (502 lines)
- **PostgreSQL Migration**: `docs/postgresql-migration.md` 
- **Firewall Setup**: `docs/firewall-setup.md`
- **Implementation Plan**: `plans/self-hosting-90-percent-coverage.md`

### **Management Scripts**
- **Monitoring**: `./scripts/manage-monitoring.sh {start|stop|status|logs}`
- **Updates**: `./scripts/manage-updates.sh {status|enable|disable|test|logs}`
- **Backups**: `./scripts/backup-n8n-encrypted.sh`

### **Configuration Files**
- **Main Config**: `.env` (n8n settings)
- **Monitoring**: `monitoring.env` (service passwords)
- **Updates**: `auto-update.conf` (update preferences)
- **Docker**: `docker-compose.monitoring.yml` (monitoring stack)

## 🎯 **Quick Validation Checklist**

### **After Initial Setup**
- [ ] Uptime Kuma accessible at http://localhost:3001
- [ ] n8n service monitored with <5min detection
- [ ] Auto-updates scheduled and verified
- [ ] Encrypted backup completed successfully
- [ ] Email notifications configured and tested
- [ ] GPG private key backed up securely offline
- [ ] All passwords saved in password manager

### **Daily Health Check**
- [ ] n8n service responding (http://localhost:5678)
- [ ] Monitoring dashboard green (http://localhost:3001)
- [ ] No alert notifications received
- [ ] Backup directory has recent files
- [ ] System resources adequate

### **Weekly Validation**
- [ ] Security audit passed
- [ ] Backup integrity verified
- [ ] Auto-update logs reviewed
- [ ] Performance metrics acceptable
- [ ] No pending security patches

### **Monthly Review**
- [ ] Backup strategy effective
- [ ] Monitoring thresholds appropriate
- [ ] Security configuration current
- [ ] Performance optimization reviewed
- [ ] Documentation updated

## 🔐 **Security Reminders**

### **Critical Security Assets**
1. **GPG Private Key**: Required for backup decryption
2. **Monitoring Passwords**: Grafana admin, Redis auth
3. **n8n Authentication**: Admin credentials
4. **Email Configuration**: Notification settings

### **Security Best Practices**
- Change default passwords immediately
- Keep GPG keys backed up offline
- Review access logs weekly
- Monitor for failed authentication attempts
- Test backup restoration quarterly
- Keep auto-updates enabled
- Use strong notification email passwords

## 📞 **Emergency Procedures**

### **Service Down**
1. Check n8n logs: `tail -f n8n-data/logs/n8n.log`
2. Restart service: `./start-n8n.sh`
3. Verify monitoring: `./scripts/manage-monitoring.sh status`
4. Check system resources: `df -h && free -h`

### **Security Incident**
1. Stop services: `pkill -f n8n`
2. Emergency lockdown: `./scripts/emergency-lockdown.sh` (if available)
3. Review logs for suspicious activity
4. Create incident backup: `./scripts/backup-n8n-encrypted.sh`
5. Follow incident response in `docs/production-hardening.md`

### **Data Recovery**
1. Locate latest backup: `ls -t backups/*.tar.gz.gpg | head -1`
2. Follow restore procedure in backup_info.txt
3. Verify GPG key availability
4. Test restored system thoroughly

---

**🎉 Result**: Production-grade n8n deployment with 90% self-hosting best practices coverage, automated security, and comprehensive operational procedures.