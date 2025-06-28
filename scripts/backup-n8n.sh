#!/bin/bash

# n8n Backup Script
# Automated backup of n8n data directory and configuration

set -e  # Exit on any error

# Configuration
BACKUP_BASE_DIR="${BACKUP_DIR:-./backups}"
N8N_DATA_DIR="${N8N_USER_FOLDER:-./n8n-data}"
ENV_FILE="./.env"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_BASE_DIR}/n8n_backup_${TIMESTAMP}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 Starting n8n backup process...${NC}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Check if n8n data directory exists
if [ ! -d "${N8N_DATA_DIR}" ]; then
    echo -e "${RED}❌ n8n data directory not found: ${N8N_DATA_DIR}${NC}"
    exit 1
fi

# Check if .env file exists
if [ ! -f "${ENV_FILE}" ]; then
    echo -e "${YELLOW}⚠️ .env file not found: ${ENV_FILE}${NC}"
    echo -e "${YELLOW}   Configuration backup skipped${NC}"
fi

echo -e "${GREEN}📁 Backing up to: ${BACKUP_DIR}${NC}"

# Backup n8n data directory
echo -e "${GREEN}📦 Backing up n8n data directory...${NC}"
cp -r "${N8N_DATA_DIR}" "${BACKUP_DIR}/n8n-data"

# Backup configuration (without sensitive data)
if [ -f "${ENV_FILE}" ]; then
    echo -e "${GREEN}⚙️ Backing up configuration...${NC}"
    # Create sanitized config backup (remove passwords)
    grep -v "PASSWORD" "${ENV_FILE}" > "${BACKUP_DIR}/.env.template" || true
    echo "# PASSWORD values removed for security" >> "${BACKUP_DIR}/.env.template"
    echo "# Restore from secure password manager" >> "${BACKUP_DIR}/.env.template"
fi

# Backup startup script
if [ -f "./start-n8n.sh" ]; then
    echo -e "${GREEN}🚀 Backing up startup script...${NC}"
    cp "./start-n8n.sh" "${BACKUP_DIR}/"
fi

# Create backup metadata
cat > "${BACKUP_DIR}/backup_info.txt" << EOF
n8n Backup Information
=====================
Backup Date: $(date)
Backup Version: 1.0
Source Data Directory: ${N8N_DATA_DIR}
Source Config File: ${ENV_FILE}

Contents:
- n8n-data/          : Complete n8n data directory
- .env.template      : Configuration template (passwords removed)
- start-n8n.sh      : Startup script
- backup_info.txt   : This file

Restore Instructions:
1. Copy n8n-data/ to your n8n installation directory
2. Copy .env.template to .env and add passwords
3. Copy start-n8n.sh and make executable: chmod +x start-n8n.sh
4. Start server: ./start-n8n.sh
EOF

# Calculate backup size
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)

echo -e "${GREEN}✅ Backup completed successfully!${NC}"
echo -e "${GREEN}📊 Backup size: ${BACKUP_SIZE}${NC}"
echo -e "${GREEN}📍 Backup location: ${BACKUP_DIR}${NC}"

# Optional: Create compressed archive
if command -v tar >/dev/null 2>&1; then
    echo -e "${GREEN}📦 Creating compressed archive...${NC}"
    cd "${BACKUP_BASE_DIR}"
    tar -czf "n8n_backup_${TIMESTAMP}.tar.gz" "n8n_backup_${TIMESTAMP}/"
    ARCHIVE_SIZE=$(du -sh "n8n_backup_${TIMESTAMP}.tar.gz" | cut -f1)
    echo -e "${GREEN}📦 Archive created: n8n_backup_${TIMESTAMP}.tar.gz (${ARCHIVE_SIZE})${NC}"
    cd - >/dev/null
fi

# Cleanup old backups (keep last 7 days)
if [ "${CLEANUP_OLD_BACKUPS:-true}" = "true" ]; then
    echo -e "${GREEN}🧹 Cleaning up old backups (keeping last 7 days)...${NC}"
    find "${BACKUP_BASE_DIR}" -name "n8n_backup_*" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
    find "${BACKUP_BASE_DIR}" -name "n8n_backup_*.tar.gz" -mtime +7 -delete 2>/dev/null || true
fi

echo -e "${GREEN}🎉 Backup process completed!${NC}"
echo ""
echo -e "${YELLOW}💡 Backup Tips:${NC}"
echo -e "${YELLOW}   - Store backups in a different location for disaster recovery${NC}"
echo -e "${YELLOW}   - Test restore procedures regularly${NC}"
echo -e "${YELLOW}   - Keep secure copies of passwords separately${NC}"
echo -e "${YELLOW}   - Consider automated scheduling with cron${NC}"