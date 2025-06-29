#!/bin/bash

# n8n Monitoring Setup Script
# Deploy 24/7 monitoring with Uptime Kuma and performance monitoring stack

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MONITORING_ENV_FILE="./monitoring.env"
DOCKER_COMPOSE_FILE="./docker-compose.monitoring.yml"

echo -e "${GREEN}📊 n8n Monitoring Setup${NC}"
echo -e "${GREEN}======================${NC}"
echo ""

# Check for Docker
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker not found. Please install Docker first:${NC}"
    echo -e "${YELLOW}   macOS: brew install docker${NC}"
    echo -e "${YELLOW}   Linux: sudo apt install docker.io${NC}"
    exit 1
fi

# Check for Docker Compose
if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker Compose not found. Please install Docker Compose${NC}"
    exit 1
fi

# Create monitoring environment file
echo -e "${GREEN}⚙️ Creating monitoring configuration...${NC}"
cat > "${MONITORING_ENV_FILE}" << EOF
# Monitoring Stack Configuration
# Generated: $(date)

# Redis Configuration
REDIS_PASSWORD=$(openssl rand -base64 32)

# Grafana Configuration  
GRAFANA_PASSWORD=$(openssl rand -base64 32)

# Prometheus Configuration
PROMETHEUS_RETENTION=15d

# Alert Configuration
ALERT_EMAIL=admin@n8n-production.local
ALERT_WEBHOOK_URL=

# Uptime Kuma Configuration
UPTIME_KUMA_PORT=3001
EOF

echo -e "${GREEN}✅ Monitoring configuration created: ${MONITORING_ENV_FILE}${NC}"

# Create Prometheus configuration
mkdir -p monitoring-config
cat > monitoring-config/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'n8n'
    static_configs:
      - targets: ['host.docker.internal:5678']
    metrics_path: '/metrics'
    scrape_interval: 30s
    scrape_timeout: 10s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['host.docker.internal:9100']
    scrape_interval: 30s

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']
EOF

# Create alert rules
cat > monitoring-config/alert_rules.yml << 'EOF'
groups:
  - name: n8n_alerts
    rules:
      - alert: N8NDown
        expr: up{job="n8n"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "n8n service is down"
          description: "n8n has been down for more than 2 minutes"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 80% for more than 5 minutes"

      - alert: DiskSpaceLow
        expr: node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} < 0.1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space"
          description: "Disk space is below 10%"
EOF

# Create Grafana provisioning
mkdir -p monitoring-config/grafana/provisioning/datasources
mkdir -p monitoring-config/grafana/provisioning/dashboards

cat > monitoring-config/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

cat > monitoring-config/grafana/provisioning/dashboards/dashboard.yml << 'EOF'
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Show deployment options
echo -e "${BLUE}Choose monitoring setup:${NC}"
echo "1. Basic monitoring (Uptime Kuma only) - Fast setup"
echo "2. Full monitoring stack (Uptime Kuma + Prometheus + Grafana) - Complete solution"
echo ""
read -p "Enter choice (1-2): " -n 1 -r
echo ""

case $REPLY in
    1)
        echo -e "${GREEN}🚀 Deploying basic monitoring...${NC}"
        docker-compose -f "${DOCKER_COMPOSE_FILE}" --env-file "${MONITORING_ENV_FILE}" up -d uptime-kuma
        
        echo -e "${GREEN}⏳ Waiting for Uptime Kuma to start...${NC}"
        sleep 10
        
        # Check if service is running
        if curl -f http://localhost:3001 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Uptime Kuma is running!${NC}"
            echo -e "${GREEN}🌐 Access at: http://localhost:3001${NC}"
        else
            echo -e "${YELLOW}⚠️ Uptime Kuma may still be starting...${NC}"
        fi
        ;;
        
    2)
        echo -e "${GREEN}🚀 Deploying full monitoring stack...${NC}"
        docker-compose -f "${DOCKER_COMPOSE_FILE}" --env-file "${MONITORING_ENV_FILE}" up -d
        
        echo -e "${GREEN}⏳ Waiting for services to start...${NC}"
        sleep 30
        
        # Check services
        echo -e "${GREEN}📊 Service Status:${NC}"
        if curl -f http://localhost:3001 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Uptime Kuma: http://localhost:3001${NC}"
        else
            echo -e "${RED}❌ Uptime Kuma: Not responding${NC}"
        fi
        
        if curl -f http://localhost:3000 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Grafana: http://localhost:3000${NC}"
            echo -e "${BLUE}   Username: admin${NC}"
            echo -e "${BLUE}   Password: $(grep GRAFANA_PASSWORD ${MONITORING_ENV_FILE} | cut -d'=' -f2)${NC}"
        else
            echo -e "${RED}❌ Grafana: Not responding${NC}"
        fi
        
        if curl -f http://localhost:9090 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Prometheus: http://localhost:9090${NC}"
        else
            echo -e "${RED}❌ Prometheus: Not responding${NC}"
        fi
        ;;
        
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

# Create monitoring management script
cat > scripts/manage-monitoring.sh << 'EOF'
#!/bin/bash

# Monitoring Management Script
ACTION="$1"
SERVICE="$2"

case "$ACTION" in
    start)
        echo "🚀 Starting monitoring services..."
        docker-compose -f docker-compose.monitoring.yml --env-file monitoring.env up -d $SERVICE
        ;;
    stop)
        echo "🛑 Stopping monitoring services..."
        docker-compose -f docker-compose.monitoring.yml stop $SERVICE
        ;;
    restart)
        echo "🔄 Restarting monitoring services..."
        docker-compose -f docker-compose.monitoring.yml restart $SERVICE
        ;;
    status)
        echo "📊 Monitoring service status:"
        docker-compose -f docker-compose.monitoring.yml ps
        ;;
    logs)
        echo "📋 Monitoring service logs:"
        docker-compose -f docker-compose.monitoring.yml logs -f $SERVICE
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs} [service]"
        echo "Services: uptime-kuma, grafana, prometheus, redis"
        exit 1
        ;;
esac
EOF

chmod +x scripts/manage-monitoring.sh

echo ""
echo -e "${GREEN}🎉 Monitoring setup completed!${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo -e "${YELLOW}   1. Configure Uptime Kuma monitors at http://localhost:3001${NC}"
echo -e "${YELLOW}   2. Add your n8n service: http://localhost:5678${NC}"
echo -e "${YELLOW}   3. Set up email/webhook notifications${NC}"
echo -e "${YELLOW}   4. Test alert notifications${NC}"
echo ""
echo -e "${BLUE}💡 Management Commands:${NC}"
echo -e "${BLUE}   Start:   ./scripts/manage-monitoring.sh start${NC}"
echo -e "${BLUE}   Stop:    ./scripts/manage-monitoring.sh stop${NC}"
echo -e "${BLUE}   Status:  ./scripts/manage-monitoring.sh status${NC}"
echo -e "${BLUE}   Logs:    ./scripts/manage-monitoring.sh logs${NC}"

# Add monitoring info to .env
if ! grep -q "MONITORING_STACK" .env 2>/dev/null; then
    echo "" >> .env
    echo "# Monitoring Configuration" >> .env
    echo "MONITORING_STACK=enabled" >> .env
    echo "MONITORING_URL=http://localhost:3001" >> .env
fi

echo ""
echo -e "${GREEN}✅ Monitoring credentials saved to: ${MONITORING_ENV_FILE}${NC}"
echo -e "${YELLOW}🔒 Keep this file secure - it contains passwords!${NC}"