# PostgreSQL Migration Guide

**Purpose:** Guide for migrating from SQLite to PostgreSQL for production scale  
**When to use:** When SQLite performance becomes insufficient for production workloads  
**Prerequisites:** PostgreSQL server available and accessible

## Overview

This guide helps migrate your n8n deployment from SQLite to PostgreSQL for better performance and scalability in production environments.

## When to Consider PostgreSQL

### SQLite Limitations
- **Concurrent Access**: Limited concurrent write operations
- **Network Access**: File-based, not suitable for distributed deployments
- **Backup Complexity**: Requires file-level backup coordination
- **Performance**: Limited performance for high-volume workflows

### PostgreSQL Benefits
- **Concurrency**: Better handling of concurrent operations
- **Network Database**: Supports distributed deployments
- **Advanced Features**: Better backup, replication, and monitoring
- **Scalability**: Handles larger datasets and higher throughput

## Migration Process

### Step 1: PostgreSQL Setup

#### Install PostgreSQL
```bash
# macOS with Homebrew
brew install postgresql
brew services start postgresql

# Create database and user
createdb n8n_production
createuser -P n8n_user  # Will prompt for password
```

#### Configure Database
```sql
-- Connect to PostgreSQL as admin
psql postgres

-- Create database and user
CREATE DATABASE n8n_production;
CREATE USER n8n_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE n8n_production TO n8n_user;

-- Exit PostgreSQL
\q
```

### Step 2: Backup Current Data

```bash
# Create backup of current SQLite setup
./scripts/backup-n8n.sh

# Stop n8n server
pkill -f "n8n" || true
```

### Step 3: Update Configuration

Create new environment file for PostgreSQL:

```bash
# Copy current configuration
cp .env .env.sqlite.backup

# Update database configuration in .env
```

Add PostgreSQL configuration to `.env`:

```bash
# Database Configuration - PostgreSQL
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n_production
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=your_secure_password

# Optional: SSL Configuration
# DB_POSTGRESDB_SSL_CA=/path/to/ca-certificate.crt
# DB_POSTGRESDB_SSL_CERT=/path/to/client-certificate.crt
# DB_POSTGRESDB_SSL_KEY=/path/to/client-key.key
# DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=true

# Connection Pool Settings
DB_POSTGRESDB_POOL_SIZE=2
```

### Step 4: Initialize PostgreSQL Database

```bash
# Start n8n to initialize database schema
N8N_SKIP_WEBHOOK_REGISTRATION=true ./start-n8n.sh

# n8n will automatically create the required tables
# Stop after initialization is complete
```

### Step 5: Data Migration (Manual)

**Note**: n8n doesn't provide automatic migration from SQLite to PostgreSQL. You'll need to recreate workflows manually or use custom migration scripts.

#### Option A: Manual Recreation (Recommended)
1. Access old SQLite-based n8n instance
2. Export workflows manually or via API
3. Import workflows into PostgreSQL-based instance

#### Option B: Database Migration Script
```bash
# This requires custom scripting - example approach:

# 1. Extract workflows from SQLite
sqlite3 n8n-data/.n8n/database.sqlite << 'EOF'
.headers on
.mode csv
.output workflows_export.csv
SELECT * FROM workflow_entity;
.quit
EOF

# 2. Process and import to PostgreSQL
# (Custom script needed based on your data)
```

### Step 6: Verification

```bash
# Start n8n with PostgreSQL
./start-n8n.sh

# Check database connection
psql -h localhost -U n8n_user -d n8n_production -c "\dt"

# Verify n8n functionality
curl -I http://localhost:5678
```

## Production Configuration

### Database Optimization

```sql
-- Connect to n8n database
psql -h localhost -U n8n_user -d n8n_production

-- Optimize for n8n workload
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

-- Reload configuration
SELECT pg_reload_conf();
```

### Connection Pool Configuration

Update `.env` for production:

```bash
# Increase connection pool for production
DB_POSTGRESDB_POOL_SIZE=10

# Connection timeout settings
DB_POSTGRESDB_ACQUIRE_TIMEOUT=60000
DB_POSTGRESDB_CREATE_TIMEOUT=30000
DB_POSTGRESDB_DESTROY_TIMEOUT=5000
DB_POSTGRESDB_IDLE_TIMEOUT=10000
DB_POSTGRESDB_REAP_INTERVAL=1000
DB_POSTGRESDB_CREATE_RETRY_INTERVAL=200
```

### SSL Configuration (Production)

```bash
# Enable SSL in production
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=true
DB_POSTGRESDB_SSL_CA=/path/to/server-ca.pem
DB_POSTGRESDB_SSL_CERT=/path/to/client-cert.pem
DB_POSTGRESDB_SSL_KEY=/path/to/client-key.pem
```

## Backup Strategy for PostgreSQL

### Automated Backup Script

Create `scripts/backup-postgresql.sh`:

```bash
#!/bin/bash

# PostgreSQL backup for n8n
BACKUP_DIR="./backups/postgresql_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Database backup
pg_dump -h localhost -U n8n_user -d n8n_production \
  --no-password --format=custom \
  --file="$BACKUP_DIR/n8n_production.backup"

# Configuration backup
cp .env "$BACKUP_DIR/.env.backup"

echo "PostgreSQL backup completed: $BACKUP_DIR"
```

### Restore from PostgreSQL Backup

```bash
# Drop existing database (CAUTION!)
dropdb n8n_production
createdb n8n_production

# Restore from backup
pg_restore -h localhost -U n8n_user -d n8n_production \
  ./backups/postgresql_20250628_120000/n8n_production.backup
```

## Rollback to SQLite

If you need to rollback to SQLite:

```bash
# Stop n8n
pkill -f "n8n" || true

# Restore SQLite configuration
cp .env.sqlite.backup .env

# Restore SQLite data
./scripts/restore-n8n.sh ./backups/n8n_backup_[timestamp]

# Start with SQLite
./start-n8n.sh
```

## Performance Monitoring

### Database Performance Queries

```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('n8n_production'));

-- Check table sizes
SELECT schemaname,tablename,
       pg_size_pretty(size) as size,
       pg_size_pretty(total_size) as total_size
FROM (
  SELECT schemaname,tablename,
         pg_relation_size(schemaname||'.'||tablename) as size,
         pg_total_relation_size(schemaname||'.'||tablename) as total_size
  FROM pg_tables WHERE schemaname='public'
) as TABLES
ORDER BY total_size DESC;

-- Check connection count
SELECT count(*) FROM pg_stat_activity WHERE datname='n8n_production';
```

### n8n Performance Monitoring

```bash
# Monitor n8n logs for database performance
tail -f n8n-data/logs/n8n.log | grep -i "database\|query\|slow"

# Check n8n metrics (if available)
curl http://localhost:5678/metrics 2>/dev/null || echo "Metrics not available"
```

## Troubleshooting

### Common Issues

#### Connection Refused
```bash
# Check PostgreSQL is running
brew services list | grep postgresql
# or
systemctl status postgresql

# Check connection
psql -h localhost -U n8n_user -d n8n_production -c "SELECT version();"
```

#### Permission Denied
```sql
-- Grant additional permissions if needed
GRANT ALL ON ALL TABLES IN SCHEMA public TO n8n_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO n8n_user;
```

#### Performance Issues
```sql
-- Check for slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

-- Analyze table statistics
ANALYZE;
```

### Migration Validation

```bash
# Test workflow creation
curl -X POST http://localhost:5678/rest/workflows \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Workflow","nodes":[],"connections":{}}'

# Test workflow execution
# Create a simple workflow via UI and test execution

# Monitor database during testing
watch "psql -h localhost -U n8n_user -d n8n_production -c 'SELECT count(*) FROM workflow_entity;'"
```

This migration guide provides a comprehensive path from SQLite to PostgreSQL while maintaining data integrity and system reliability.