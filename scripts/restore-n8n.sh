#!/bin/bash

# n8n Restore Script
# Restore n8n data from backup

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage function
usage() {
    echo "Usage: $0 <backup_directory_or_archive>"
    echo ""
    echo "Examples:"
    echo "  $0 ./backups/n8n_backup_20250628_120000"
    echo "  $0 ./backups/n8n_backup_20250628_120000.tar.gz"
    echo ""
    exit 1
}

# Check arguments
if [ $# -ne 1 ]; then
    usage
fi

BACKUP_SOURCE="$1"
CURRENT_DIR=$(pwd)
N8N_DATA_DIR="${N8N_USER_FOLDER:-./n8n-data}"

echo -e "${GREEN}🔄 Starting n8n restore process...${NC}"

# Check if backup source exists
if [ ! -e "${BACKUP_SOURCE}" ]; then
    echo -e "${RED}❌ Backup source not found: ${BACKUP_SOURCE}${NC}"
    exit 1
fi

# Handle compressed archive
if [[ "${BACKUP_SOURCE}" == *.tar.gz ]]; then
    echo -e "${GREEN}📦 Extracting compressed archive...${NC}"
    TEMP_DIR=$(mktemp -d)
    tar -xzf "${BACKUP_SOURCE}" -C "${TEMP_DIR}"
    BACKUP_DIR="${TEMP_DIR}/$(basename "${BACKUP_SOURCE}" .tar.gz)"
else
    BACKUP_DIR="${BACKUP_SOURCE}"
fi

# Verify backup directory structure
if [ ! -d "${BACKUP_DIR}" ]; then
    echo -e "${RED}❌ Invalid backup directory: ${BACKUP_DIR}${NC}"
    exit 1
fi

if [ ! -f "${BACKUP_DIR}/backup_info.txt" ]; then
    echo -e "${YELLOW}⚠️ Warning: backup_info.txt not found. Proceeding anyway...${NC}"
fi

echo -e "${GREEN}📍 Restoring from: ${BACKUP_DIR}${NC}"

# Show backup information if available
if [ -f "${BACKUP_DIR}/backup_info.txt" ]; then
    echo -e "${GREEN}📋 Backup Information:${NC}"
    cat "${BACKUP_DIR}/backup_info.txt" | head -10
    echo ""
fi

# Confirm restoration
echo -e "${YELLOW}⚠️ This will replace your current n8n data and configuration!${NC}"
echo -e "${YELLOW}   Current data directory: ${N8N_DATA_DIR}${NC}"
echo -e "${YELLOW}   Current config file: ./.env${NC}"
echo ""
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Restore cancelled${NC}"
    exit 1
fi

# Create backup of current data (if exists)
if [ -d "${N8N_DATA_DIR}" ]; then
    BACKUP_CURRENT_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_CURRENT_DIR="./backups/pre_restore_${BACKUP_CURRENT_TIMESTAMP}"
    echo -e "${GREEN}💾 Backing up current data to: ${BACKUP_CURRENT_DIR}${NC}"
    mkdir -p "${BACKUP_CURRENT_DIR}"
    cp -r "${N8N_DATA_DIR}" "${BACKUP_CURRENT_DIR}/"
    if [ -f "./.env" ]; then
        cp "./.env" "${BACKUP_CURRENT_DIR}/"
    fi
fi

# Stop n8n if running
echo -e "${GREEN}🛑 Stopping n8n server (if running)...${NC}"
pkill -f "n8n" 2>/dev/null || true
sleep 2

# Restore n8n data
if [ -d "${BACKUP_DIR}/n8n-data" ]; then
    echo -e "${GREEN}📁 Restoring n8n data directory...${NC}"
    rm -rf "${N8N_DATA_DIR}"
    cp -r "${BACKUP_DIR}/n8n-data" "${N8N_DATA_DIR}"
    echo -e "${GREEN}✅ Data directory restored${NC}"
else
    echo -e "${RED}❌ No n8n-data directory found in backup${NC}"
    exit 1
fi

# Restore configuration template
if [ -f "${BACKUP_DIR}/.env.template" ]; then
    echo -e "${GREEN}⚙️ Configuration template found${NC}"
    if [ -f "./.env" ]; then
        echo -e "${YELLOW}⚠️ Existing .env file found. Creating .env.restored instead${NC}"
        cp "${BACKUP_DIR}/.env.template" "./.env.restored"
        echo -e "${YELLOW}   Please review .env.restored and merge with your current .env${NC}"
    else
        cp "${BACKUP_DIR}/.env.template" "./.env"
        echo -e "${YELLOW}⚠️ Please add your passwords to .env file before starting n8n${NC}"
    fi
fi

# Restore startup script
if [ -f "${BACKUP_DIR}/start-n8n.sh" ]; then
    echo -e "${GREEN}🚀 Restoring startup script...${NC}"
    cp "${BACKUP_DIR}/start-n8n.sh" "./"
    chmod +x "./start-n8n.sh"
fi

# Cleanup temporary directory if used
if [[ "${BACKUP_SOURCE}" == *.tar.gz ]] && [ -n "${TEMP_DIR}" ]; then
    rm -rf "${TEMP_DIR}"
fi

# Set proper permissions
echo -e "${GREEN}🔐 Setting proper permissions...${NC}"
chmod -R 755 "${N8N_DATA_DIR}"

echo -e "${GREEN}✅ Restore completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo -e "${YELLOW}   1. Verify .env file has correct passwords${NC}"
echo -e "${YELLOW}   2. Start n8n server: ./start-n8n.sh${NC}"
echo -e "${YELLOW}   3. Access web interface: http://localhost:5678${NC}"
echo -e "${YELLOW}   4. Verify your workflows are working correctly${NC}"
echo ""
echo -e "${GREEN}🎉 Restore process completed!${NC}"