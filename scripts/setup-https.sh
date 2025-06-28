#!/bin/bash

# n8n HTTPS Setup Script
# Configure SSL certificates and HTTPS for n8n

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${N8N_DOMAIN:-localhost}"
SSL_DIR="./ssl"
ENV_FILE="./.env"

echo -e "${GREEN}🔐 n8n HTTPS Setup${NC}"
echo -e "${GREEN}==================${NC}"
echo ""

# Check if mkcert is available
if command -v mkcert >/dev/null 2>&1; then
    echo -e "${GREEN}✅ mkcert found - can generate local SSL certificates${NC}"
    MKCERT_AVAILABLE=true
else
    echo -e "${YELLOW}⚠️ mkcert not found - manual certificate setup required${NC}"
    MKCERT_AVAILABLE=false
fi

# Show options
echo -e "${BLUE}Choose SSL certificate option:${NC}"
echo "1. Generate local SSL certificates with mkcert (recommended for development)"
echo "2. Use existing SSL certificates"
echo "3. Configure for production SSL (Let's Encrypt guidance)"
echo ""
read -p "Enter choice (1-3): " -n 1 -r
echo ""

case $REPLY in
    1)
        if [ "$MKCERT_AVAILABLE" = false ]; then
            echo -e "${RED}❌ mkcert not available. Please install mkcert first:${NC}"
            echo -e "${YELLOW}   macOS: brew install mkcert${NC}"
            echo -e "${YELLOW}   Linux: see https://github.com/FiloSottile/mkcert${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}📁 Creating SSL directory...${NC}"
        mkdir -p "${SSL_DIR}"
        
        echo -e "${GREEN}🔑 Generating local SSL certificates...${NC}"
        cd "${SSL_DIR}"
        mkcert -install 2>/dev/null || echo "Root CA already installed"
        mkcert "${DOMAIN}" "*.${DOMAIN}" 2>/dev/null
        
        # Find generated files
        CERT_FILE=$(ls ${DOMAIN}+*.pem | head -1)
        KEY_FILE=$(ls ${DOMAIN}+*-key.pem | head -1)
        
        if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
            echo -e "${GREEN}✅ SSL certificates generated:${NC}"
            echo -e "${GREEN}   Certificate: ${SSL_DIR}/${CERT_FILE}${NC}"
            echo -e "${GREEN}   Private Key: ${SSL_DIR}/${KEY_FILE}${NC}"
            
            # Update .env file
            cd ..
            update_env_for_https "${SSL_DIR}/${CERT_FILE}" "${SSL_DIR}/${KEY_FILE}"
        else
            echo -e "${RED}❌ Certificate generation failed${NC}"
            exit 1
        fi
        ;;
        
    2)
        echo -e "${YELLOW}📋 Manual SSL certificate setup${NC}"
        echo ""
        read -p "Enter path to SSL certificate file: " CERT_PATH
        read -p "Enter path to SSL private key file: " KEY_PATH
        
        if [ ! -f "$CERT_PATH" ]; then
            echo -e "${RED}❌ Certificate file not found: $CERT_PATH${NC}"
            exit 1
        fi
        
        if [ ! -f "$KEY_PATH" ]; then
            echo -e "${RED}❌ Private key file not found: $KEY_PATH${NC}"
            exit 1
        fi
        
        update_env_for_https "$CERT_PATH" "$KEY_PATH"
        ;;
        
    3)
        echo -e "${BLUE}🌐 Production SSL Setup Guide${NC}"
        echo -e "${BLUE}=============================${NC}"
        echo ""
        echo -e "${YELLOW}For production deployment with Let's Encrypt:${NC}"
        echo ""
        echo "1. Set up a reverse proxy (nginx/Apache) with SSL termination"
        echo "2. Use Certbot to obtain Let's Encrypt certificates"
        echo "3. Configure n8n to run behind the proxy"
        echo ""
        echo -e "${YELLOW}Example nginx configuration:${NC}"
        cat << 'EOF'
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
        echo ""
        echo -e "${YELLOW}In this setup, keep n8n on HTTP and let nginx handle SSL${NC}"
        echo -e "${YELLOW}Set N8N_HOST=127.0.0.1 for security (nginx proxy only)${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉 HTTPS setup completed!${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo -e "${YELLOW}   1. Restart n8n server: ./start-n8n.sh${NC}"
echo -e "${YELLOW}   2. Access via HTTPS: https://${DOMAIN}:5678${NC}"
echo -e "${YELLOW}   3. Accept security warning for self-signed certificates${NC}"
echo ""
echo -e "${BLUE}💡 Security Notes:${NC}"
echo -e "${BLUE}   - Self-signed certificates will show browser warnings${NC}"
echo -e "${BLUE}   - For production, use proper SSL certificates${NC}"
echo -e "${BLUE}   - Keep SSL private keys secure and backed up${NC}"

# Function to update .env file for HTTPS
update_env_for_https() {
    local cert_path="$1"
    local key_path="$2"
    
    echo -e "${GREEN}⚙️ Updating .env configuration for HTTPS...${NC}"
    
    # Backup current .env
    cp "${ENV_FILE}" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update protocol
    if grep -q "^N8N_PROTOCOL=" "${ENV_FILE}"; then
        sed -i '' 's/^N8N_PROTOCOL=.*/N8N_PROTOCOL=https/' "${ENV_FILE}"
    else
        echo "N8N_PROTOCOL=https" >> "${ENV_FILE}"
    fi
    
    # Update secure cookie setting
    if grep -q "^N8N_SECURE_COOKIE=" "${ENV_FILE}"; then
        sed -i '' 's/^N8N_SECURE_COOKIE=.*/N8N_SECURE_COOKIE=true/' "${ENV_FILE}"
    else
        echo "N8N_SECURE_COOKIE=true" >> "${ENV_FILE}"
    fi
    
    # Add SSL certificate paths
    if ! grep -q "^N8N_SSL_CERT=" "${ENV_FILE}"; then
        echo "" >> "${ENV_FILE}"
        echo "# SSL Configuration" >> "${ENV_FILE}"
        echo "N8N_SSL_CERT=${cert_path}" >> "${ENV_FILE}"
        echo "N8N_SSL_KEY=${key_path}" >> "${ENV_FILE}"
    fi
    
    echo -e "${GREEN}✅ .env file updated for HTTPS${NC}"
}