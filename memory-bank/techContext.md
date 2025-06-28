# Technical Context: Technology Stack & Constraints

**Purpose:** Technologies used, development setup, and technical constraints  
**When to use:** Understanding technical foundation and development environment  
**Size:** 🟢 AI-friendly (<400 lines)

## Technology Stack

### Core Platform
- **n8n**: v1.99.1 - Workflow automation platform
- **Node.js**: v23.10.0 - JavaScript runtime environment
- **npm**: v10.9.2 - Package manager and installation tool
- **SQLite**: Database for workflow and execution storage

### Operating Environment
- **Platform**: macOS (Darwin 24.5.0)
- **Installation Method**: Global npm installation via Homebrew
- **Architecture**: Single-server deployment
- **Protocol**: HTTP (HTTPS recommended for production)

### Development Tools
- **Git**: Version control with mandatory feature branch workflow
- **GitHub CLI**: Issue tracking and PR management
- **Shell Scripts**: Deployment automation and server management
- **Environment Variables**: Configuration management

### Security Stack
- **Basic Authentication**: Admin user with secure password
- **Pre-commit Validation**: Credential scanning and security checks
- **Environment Protection**: Secure variable management
- **Git Compliance**: Branch protection and workflow enforcement

### AI Development Tools
- **Claude Code**: Primary AI assistant for development and documentation
- **Cursor**: Code editing and pattern following
- **TodoWrite**: Task management and coordination
- **Multi-Agent Protocols**: Collaboration between AI assistants

## Development Setup

### System Requirements
```bash
# Required Software
Node.js: >= 18.0.0 (current: v23.10.0)
npm: >= 8.0.0 (current: v10.9.2)
Git: Any recent version
```

### Installation Process
```bash
# Global n8n Installation
npm install n8n -g

# Verify Installation
n8n --version  # Should show: 1.99.1
which n8n      # Should show: /opt/homebrew/bin/n8n
```

### Configuration Files
```
.env                    # Environment variables and server config
start-n8n.sh           # Server startup script
n8n-data/              # Runtime data directory
├── .n8n/config        # User settings and encryption keys
├── database.sqlite    # Workflow and execution storage
├── logs/              # Application logs
└── binaryData/        # File upload storage
```

### Development Environment
```bash
# Server Management
./start-n8n.sh         # Start n8n server
curl -I http://localhost:5678  # Check server status
ps aux | grep n8n      # Check process status

# Configuration Management
cat .env               # View current configuration
openssl rand -base64 32  # Generate secure passwords
```

## Technical Constraints

### Architecture Constraints
- **Single Server Only**: Not designed for distributed deployment
- **SQLite Database**: File-based database, not enterprise-scale
- **Local Network**: Designed for localhost or single-server production
- **Basic Authentication**: Simple auth, not enterprise SSO

### Security Constraints
- **No Credential Storage**: Real credentials never in git repository
- **Environment Variable Only**: All secrets via environment variables
- **Pre-commit Validation**: All commits must pass security scanning
- **Git Workflow**: Feature branches mandatory, never commit to main

### Performance Constraints
- **SQLite Limits**: Database performance limited by file system
- **Single Process**: Not horizontally scalable without architecture changes
- **Memory Usage**: Limited by single Node.js process
- **Concurrent Workflows**: Limited by server resources

### Development Constraints
- **Documentation Standards**: Must follow memory bank framework
- **AI Context Limits**: File size categories for optimal AI usage
- **Security Validation**: Mandatory validation before all commits
- **Multi-Agent Coordination**: Required patterns for AI collaboration

## Configuration Management

### Environment Variables
```bash
# Server Configuration
N8N_PORT=5678                    # Server port
N8N_HOST=0.0.0.0                 # Bind address
N8N_PROTOCOL=http                # Protocol (HTTPS for production)

# Authentication
N8N_BASIC_AUTH_ACTIVE=true       # Enable basic auth
N8N_BASIC_AUTH_USER=admin        # Username
N8N_BASIC_AUTH_PASSWORD=secure   # Generated password

# Data Storage
N8N_USER_FOLDER=/path/to/n8n-data  # Data directory
DB_TYPE=sqlite                   # Database type

# Logging
N8N_LOG_LEVEL=info              # Log verbosity
N8N_LOG_OUTPUT=console,file     # Log destinations
```

### Security Configuration
```bash
# Security Validation (Pre-commit)
git status --porcelain | grep "^\.env$"  # Check for .env in staging
git diff --cached | grep -E "API key patterns"  # Scan for credentials
STAGED=$(git diff --cached --name-only)  # Check staged files
```

### File System Layout
```
/Users/teamlift/GitHub/N8N/
├── .env                        # Environment configuration
├── start-n8n.sh              # Startup script
├── README.md                  # Setup documentation
├── CLAUDE.md                  # Development workflows
├── memory-bank/               # Documentation system
└── n8n-data/                 # Runtime data
    ├── .n8n/                 # User configuration
    ├── .cache/               # UI assets cache
    └── logs/                 # Application logs
```

## Integration Points

### n8n Platform Integration
- **Global Installation**: System-wide n8n availability
- **Data Persistence**: SQLite database for workflows
- **Web Interface**: Browser-based workflow editor
- **API Access**: REST API for programmatic access

### Development Workflow Integration
- **Git Integration**: Version control for all project files
- **GitHub Integration**: Issue tracking and PR management
- **AI Tool Integration**: Claude Code, Cursor coordination
- **Security Integration**: Pre-commit validation hooks

### System Integration
- **Shell Environment**: Command-line tools and scripts
- **File System**: Local file storage and configuration
- **Network Services**: HTTP server for web interface
- **Process Management**: Node.js process supervision

## Deployment Architecture

### Production Deployment Pattern
```bash
# Deployment Steps
1. Clone repository
2. Configure .env file
3. Run ./start-n8n.sh
4. Access web interface
5. Begin workflow creation
```

### Data Management
```bash
# Data Backup
cp -r n8n-data/ backup-$(date +%Y%m%d)/

# Configuration Backup
cp .env .env.backup

# Log Management
tail -f n8n-data/logs/*.log
```

### Monitoring & Health Checks
```bash
# Server Health
curl -I http://localhost:5678     # HTTP health check
ps aux | grep n8n                # Process status
du -sh n8n-data/                 # Data size monitoring
```

## Scalability Considerations

### Current Limitations
- **Single Process**: Node.js single-threaded limitations
- **SQLite Performance**: File database performance ceiling
- **Local Storage**: File system storage limitations
- **Network Scope**: Single server network accessibility

### Scaling Options
- **Database Migration**: SQLite → PostgreSQL for performance
- **Process Scaling**: Multiple n8n instances with load balancing
- **Storage Scaling**: Network attached storage for data
- **Network Scaling**: Reverse proxy for external access

### Migration Paths
- **Database**: Migrate workflows from SQLite to PostgreSQL
- **Authentication**: Upgrade from basic auth to OAuth/SAML
- **Deployment**: Container-based deployment for scalability
- **Monitoring**: Enterprise monitoring and alerting systems

## Security Architecture

### Security Layers
```bash
# Application Security
- Basic authentication for web interface
- Environment variable configuration
- No hardcoded credentials

# Development Security  
- Pre-commit credential scanning
- Git workflow enforcement
- Security validation mandatory

# Operational Security
- Local network deployment
- File system access controls
- Process isolation
```

### Security Validation
```bash
# Pre-commit Security Check
echo "🔒 Security validation..."
git status --porcelain | grep "^\.env$" && echo "❌ .env staged!" && exit 1
git diff --cached | grep -E "(API key patterns)" && echo "❌ API key!" && exit 1
echo "✅ Safe to commit"
```

This technical context provides the foundation for understanding the technical environment and constraints for all development work on the n8n deployment project.