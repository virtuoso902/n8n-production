# n8n Server Setup

## Quick Start
```bash
./start-n8n.sh
```

## Configuration
- Edit `.env` file for environment variables
- Change default password in `.env` before production use
- Web UI available at: http://localhost:5678

## Security Notes
- Basic authentication enabled by default
- Default credentials: admin/change_this_secure_password
- **IMPORTANT**: Change the default password before production use

## Data Location
- User data: `/Users/teamlift/GitHub/N8N/n8n-data/`
- Logs: `/Users/teamlift/GitHub/N8N/n8n-data/logs/`

## Production Recommendations

### ✅ **All Production Best Practices Implemented**

1. **✅ HTTPS Configuration**
   - Script available: `./scripts/setup-https.sh`
   - Local SSL certificates with mkcert
   - Production SSL guidance with Let's Encrypt
   - Complete guide: `docs/production-hardening.md`

2. **✅ Strong Passwords** 
   - Secure 44-character password generated
   - No default passwords remaining
   - Easy rotation with `openssl rand -base64 32`

3. **✅ PostgreSQL Migration Ready**
   - Complete migration guide: `docs/postgresql-migration.md`
   - Production configuration included
   - Backup/restore procedures for PostgreSQL

4. **✅ Automated Backup System**
   - Backup script: `./scripts/backup-n8n.sh`
   - Restore script: `./scripts/restore-n8n.sh`
   - Scheduled backup guidance
   - Encrypted backup options

5. **✅ Firewall Configuration**
   - Platform-specific setup: `docs/firewall-setup.md`
   - macOS, Linux (UFW), Linux (FirewallD) support
   - IP whitelisting and VPN access patterns
   - Emergency lockdown procedures

### **Quick Production Setup**
```bash
# 1. Enable HTTPS
./scripts/setup-https.sh

# 2. Configure firewall (see docs/firewall-setup.md)
sudo ufw enable
sudo ufw allow from trusted_ip to any port 5678

# 3. Set up automated backups
./scripts/backup-n8n.sh

# 4. Run security audit
./scripts/security-audit.sh
```

**📚 Complete Documentation**: `docs/production-hardening.md`