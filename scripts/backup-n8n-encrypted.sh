#!/bin/bash

# n8n Encrypted Backup Script
# Automated backup with GPG encryption for production security

set -e  # Exit on any error

# Configuration
BACKUP_BASE_DIR="${BACKUP_DIR:-./backups}"
N8N_DATA_DIR="${N8N_USER_FOLDER:-./n8n-data}"
ENV_FILE="./.env"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_BASE_DIR}/n8n_backup_${TIMESTAMP}"
GPG_RECIPIENT="${GPG_RECIPIENT:-}"
ENCRYPT_ENABLED="${ENCRYPT_BACKUPS:-true}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 Starting n8n encrypted backup process...${NC}"

# Check for GPG if encryption is enabled
if [ "$ENCRYPT_ENABLED" = "true" ]; then
    if ! command -v gpg >/dev/null 2>&1; then
        echo -e "${RED}❌ GPG not found. Install with:${NC}"
        echo -e "${YELLOW}   macOS: brew install gnupg${NC}"
        echo -e "${YELLOW}   Linux: sudo apt install gnupg${NC}"
        exit 1
    fi
    
    # Check for GPG key
    if [ -z "$GPG_RECIPIENT" ]; then
        echo -e "${BLUE}🔑 No GPG recipient specified. Checking for existing keys...${NC}"
        GPG_KEYS=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -E "^sec" | head -1 | cut -d'/' -f2 | cut -d' ' -f1 || echo "")
        if [ -n "$GPG_KEYS" ]; then
            GPG_RECIPIENT="$GPG_KEYS"
            echo -e "${GREEN}✅ Using existing GPG key: ${GPG_RECIPIENT}${NC}"
        else
            echo -e "${YELLOW}⚠️ No GPG keys found. Generating new key...${NC}"
            generate_gpg_key
        fi
    fi
fi

generate_gpg_key() {
    echo -e "${BLUE}🔑 Generating new GPG key for backups...${NC}"
    
    cat > /tmp/gpg_batch_params << EOF
%echo Generating GPG key for n8n backups
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: n8n Backup
Name-Email: backup@n8n-production.local
Expire-Date: 2y
Passphrase: $(openssl rand -base64 32)
%commit
%echo Done
EOF

    gpg --batch --generate-key /tmp/gpg_batch_params
    rm /tmp/gpg_batch_params
    
    # Get the new key ID
    GPG_RECIPIENT=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -E "^sec" | head -1 | cut -d'/' -f2 | cut -d' ' -f1)
    echo -e "${GREEN}✅ GPG key generated: ${GPG_RECIPIENT}${NC}"
    echo -e "${YELLOW}💡 Save this key ID for future backups: ${GPG_RECIPIENT}${NC}"
}

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Check if n8n data directory exists
if [ ! -d "${N8N_DATA_DIR}" ]; then
    echo -e "${RED}❌ n8n data directory not found: ${N8N_DATA_DIR}${NC}"
    exit 1
fi

echo -e "${GREEN}📁 Backing up to: ${BACKUP_DIR}${NC}"

# Backup n8n data directory
echo -e "${GREEN}📦 Backing up n8n data directory...${NC}"
cp -r "${N8N_DATA_DIR}" "${BACKUP_DIR}/n8n-data"

# Backup configuration securely
if [ -f "${ENV_FILE}" ]; then
    echo -e "${GREEN}⚙️ Backing up configuration...${NC}"
    if [ "$ENCRYPT_ENABLED" = "true" ]; then
        # Encrypt the full .env file
        gpg --trust-model always --encrypt --armor -r "${GPG_RECIPIENT}" --output "${BACKUP_DIR}/.env.gpg" "${ENV_FILE}"
        echo -e "${GREEN}🔐 Configuration encrypted: .env.gpg${NC}"
    else
        # Create sanitized version if encryption disabled
        grep -v "PASSWORD" "${ENV_FILE}" > "${BACKUP_DIR}/.env.template" || true
        echo "# PASSWORD values removed for security" >> "${BACKUP_DIR}/.env.template"
    fi
fi

# Backup startup script
if [ -f "./start-n8n.sh" ]; then
    echo -e "${GREEN}🚀 Backing up startup script...${NC}"
    cp "./start-n8n.sh" "${BACKUP_DIR}/"
fi

# Backup additional scripts
if [ -d "./scripts" ]; then
    echo -e "${GREEN}📋 Backing up utility scripts...${NC}"
    cp -r "./scripts" "${BACKUP_DIR}/"
fi

# Create backup metadata
cat > "${BACKUP_DIR}/backup_info.txt" << EOF
n8n Encrypted Backup Information
================================
Backup Date: $(date)
Backup Version: 2.0 (Encrypted)
Source Data Directory: ${N8N_DATA_DIR}
Source Config File: ${ENV_FILE}
Encryption Enabled: ${ENCRYPT_ENABLED}
GPG Key ID: ${GPG_RECIPIENT:-N/A}

Contents:
- n8n-data/          : Complete n8n data directory
- .env.gpg           : Encrypted configuration file (if encryption enabled)
- .env.template      : Configuration template (if encryption disabled)
- start-n8n.sh      : Startup script
- scripts/           : Utility scripts directory
- backup_info.txt   : This file

Restore Instructions:
1. Copy n8n-data/ to your n8n installation directory
2. Decrypt configuration: gpg --decrypt .env.gpg > .env
3. Copy start-n8n.sh and make executable: chmod +x start-n8n.sh
4. Copy scripts/ directory
5. Start server: ./start-n8n.sh

Security Notes:
- Configuration file is encrypted with GPG key: ${GPG_RECIPIENT:-N/A}
- Keep GPG private key secure and backed up separately
- Test decryption process regularly
EOF

# Calculate backup size
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)

echo -e "${GREEN}✅ Backup completed successfully!${NC}"
echo -e "${GREEN}📊 Backup size: ${BACKUP_SIZE}${NC}"
echo -e "${GREEN}📍 Backup location: ${BACKUP_DIR}${NC}"

# Create encrypted compressed archive
if command -v tar >/dev/null 2>&1; then
    echo -e "${GREEN}📦 Creating compressed archive...${NC}"
    cd "${BACKUP_BASE_DIR}"
    
    if [ "$ENCRYPT_ENABLED" = "true" ]; then
        # Create encrypted archive
        tar -czf - "n8n_backup_${TIMESTAMP}/" | gpg --trust-model always --encrypt --armor -r "${GPG_RECIPIENT}" --output "n8n_backup_${TIMESTAMP}.tar.gz.gpg"
        ARCHIVE_SIZE=$(du -sh "n8n_backup_${TIMESTAMP}.tar.gz.gpg" | cut -f1)
        echo -e "${GREEN}🔐 Encrypted archive created: n8n_backup_${TIMESTAMP}.tar.gz.gpg (${ARCHIVE_SIZE})${NC}"
        
        # Remove unencrypted directory for security
        rm -rf "n8n_backup_${TIMESTAMP}/"
        echo -e "${GREEN}🗑️ Unencrypted backup directory removed for security${NC}"
    else
        # Create standard archive
        tar -czf "n8n_backup_${TIMESTAMP}.tar.gz" "n8n_backup_${TIMESTAMP}/"
        ARCHIVE_SIZE=$(du -sh "n8n_backup_${TIMESTAMP}.tar.gz" | cut -f1)
        echo -e "${GREEN}📦 Archive created: n8n_backup_${TIMESTAMP}.tar.gz (${ARCHIVE_SIZE})${NC}"
    fi
    
    cd - >/dev/null
fi

# Create restore script
cat > "${BACKUP_BASE_DIR}/restore-backup-${TIMESTAMP}.sh" << 'EOF'
#!/bin/bash
# Automated restore script for encrypted backup

set -e

BACKUP_FILE="$1"
RESTORE_DIR="${2:-./n8n-restored}"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file.tar.gz.gpg> [restore_directory]"
    exit 1
fi

echo "🔄 Restoring encrypted n8n backup..."

# Check if encrypted
if [[ "$BACKUP_FILE" == *.gpg ]]; then
    echo "🔐 Decrypting backup..."
    gpg --decrypt "$BACKUP_FILE" | tar -xzf - -C "$(dirname "$RESTORE_DIR")"
    echo "✅ Backup decrypted and extracted"
else
    echo "📦 Extracting standard backup..."
    tar -xzf "$BACKUP_FILE" -C "$(dirname "$RESTORE_DIR")"
fi

echo "✅ Restore completed to: $RESTORE_DIR"
echo "📝 Check backup_info.txt for restore instructions"
EOF

chmod +x "${BACKUP_BASE_DIR}/restore-backup-${TIMESTAMP}.sh"

# Cleanup old backups (keep last 7 days)
if [ "${CLEANUP_OLD_BACKUPS:-true}" = "true" ]; then
    echo -e "${GREEN}🧹 Cleaning up old backups (keeping last 7 days)...${NC}"
    find "${BACKUP_BASE_DIR}" -name "n8n_backup_*" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
    find "${BACKUP_BASE_DIR}" -name "n8n_backup_*.tar.gz*" -mtime +7 -delete 2>/dev/null || true
    find "${BACKUP_BASE_DIR}" -name "restore-backup-*.sh" -mtime +7 -delete 2>/dev/null || true
fi

echo -e "${GREEN}🎉 Encrypted backup process completed!${NC}"
echo ""
echo -e "${YELLOW}💡 Security Tips:${NC}"
echo -e "${YELLOW}   - Store encrypted backups in different location${NC}"
echo -e "${YELLOW}   - Backup GPG private key separately: gpg --export-secret-key ${GPG_RECIPIENT} > private-key.asc${NC}"
echo -e "${YELLOW}   - Test decryption regularly: gpg --decrypt backup.tar.gz.gpg | tar -tzf -${NC}"
echo -e "${YELLOW}   - Use strong GPG passphrase and store securely${NC}"

if [ "$ENCRYPT_ENABLED" = "true" ]; then
    echo ""
    echo -e "${BLUE}🔑 GPG Key Information:${NC}"
    echo -e "${BLUE}   Key ID: ${GPG_RECIPIENT}${NC}"
    echo -e "${BLUE}   Export public key: gpg --export --armor ${GPG_RECIPIENT} > public-key.asc${NC}"
    echo -e "${BLUE}   Import on restore system: gpg --import public-key.asc private-key.asc${NC}"
fi