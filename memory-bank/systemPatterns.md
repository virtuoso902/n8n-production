# System Patterns: Architecture & Development

**Purpose:** System architecture, key technical decisions, and design patterns  
**When to use:** Understanding technical foundation and development patterns  
**Size:** 🟢 AI-friendly (<400 lines)

## Architecture Overview

### System Architecture

This n8n deployment follows a **production-ready single-server architecture** with security-first design:

```
┌─────────────────────────────────────────┐
│ n8n Production Deployment               │
├─────────────────────────────────────────┤
│ Web Interface (localhost:5678)          │
│ ├── Basic Authentication               │
│ ├── Workflow Editor                    │
│ └── Execution Monitoring               │
├─────────────────────────────────────────┤
│ n8n Server (Global Installation)        │
│ ├── SQLite Database                    │
│ ├── Environment Configuration          │
│ ├── File Storage (n8n-data)           │
│ └── Logging System                     │
├─────────────────────────────────────────┤
│ Security Layer                          │
│ ├── Pre-commit Validation             │
│ ├── Credential Scanning               │
│ ├── Environment Protection            │
│ └── Git Workflow Enforcement          │
├─────────────────────────────────────────┤
│ Development Layer                       │
│ ├── AI Documentation System           │
│ ├── Multi-Agent Coordination          │
│ ├── TodoWrite Management              │
│ └── Error Recovery Procedures         │
└─────────────────────────────────────────┘
```

### Key Design Decisions

#### 1. Security-First Architecture
- **Pre-commit Validation**: All commits validated for credentials and security
- **Environment Protection**: No hardcoded values, explicit validation
- **Fail-Fast Patterns**: Immediate failure rather than silent fallbacks
- **Authentication Required**: Basic auth enforced for all access

#### 2. AI-Optimized Documentation
- **Memory Bank System**: Domain-driven modular documentation
- **File Size Categories**: 🔴🟡🟢 for optimal AI context usage
- **Section Navigation**: Stable ## headers for reliable references
- **Task-Specific Paths**: Guided navigation for common scenarios

#### 3. Production-Ready Deployment
- **Single Server Focus**: Optimized for local/single-server production
- **SQLite Database**: Reliable, file-based storage for workflows
- **Environment Configuration**: Secure, flexible configuration management
- **Startup Automation**: Shell script for consistent deployment

## Development Patterns

### Git Workflow Pattern

**Never Commit to Main**: Absolute enforcement of feature branch workflow

```bash
# Standard Pattern
feature/issue-number-description     # New functionality
fix/issue-number-bug-description     # Bug fixes  
quick/issue-number-task             # <30 minute tasks
team/agent-name/issue-number        # Multi-agent work
```

**Security Validation**: Mandatory pre-commit checks
```bash
# Security Pattern
1. Check for .env files in staging
2. Scan for API keys and credentials
3. Validate hardcoded secrets
4. Pass validation before commit
```

### AI Collaboration Pattern

**Multi-Agent Coordination**: Structured collaboration between AI assistants

```bash
# Coordination Pattern
1. Agent Detection: Check for existing work
2. Branch Creation: team/agent-name/issue-number
3. Progress Updates: Regular issue comments
4. Handoff Documentation: Detailed work summaries
5. Conflict Resolution: Systematic merge strategies
```

**Context Optimization**: Efficient documentation usage
```bash
# Usage Pattern
1. Start with startHere.md navigation
2. Follow task-specific paths
3. Use section navigation (## headers)
4. Load incrementally by file size category
```

### TodoWrite Management Pattern

**Mandatory Usage**: Required for complex tasks
- 3+ step tasks
- Git operations  
- Security changes
- Multi-agent work

**Enforcement Rules**:
- ONE task in_progress at any time
- Mark completed IMMEDIATELY after finishing
- NEVER mark completed unless 100% done

### Error Recovery Pattern

**Graduated Response**: Systematic error handling
```bash
# Recovery Pattern
1. Immediate Assessment: Understand scope and impact
2. Containment: Prevent further damage
3. Recovery Actions: Systematic repair procedures
4. Documentation: Log incident and lessons learned
5. Prevention: Update safeguards and procedures
```

## Technical Patterns

### Configuration Management

**Environment Variables**: Secure configuration pattern
```bash
# Configuration Pattern
- Required validation for production variables
- No localhost fallbacks in production code
- Explicit error messages for missing config
- Dummy values only in test environments
```

**File Organization**: Structured deployment layout
```
n8n-data/              # Runtime data
├── .n8n/             # User configuration
│   ├── database.sqlite # Workflow storage
│   ├── nodes/         # Custom nodes (ready)
│   └── binaryData/    # File uploads
├── .cache/           # UI assets cache
└── logs/             # Application logs
```

### Security Patterns

**Credential Protection**: Zero credential exposure
- Environment variable references only
- Pre-commit scanning validation
- Emergency revocation procedures
- Clean git history maintenance

**Access Control**: Production-ready authentication
- Basic authentication required
- Secure password generation
- Password rotation support
- Session management

### Documentation Patterns

**Memory Bank Structure**: AI-optimized organization
```
memory-bank/
├── Navigation Layer    # startHere.md, AI_GUIDE.md
├── Core Context       # projectbrief.md, productContext.md
├── Current State      # activeContext.md, progress.md
├── Technical Foundation # systemPatterns.md, techContext.md
└── Feature Documentation # Modular feature folders
```

**File Size Management**: Context efficiency
- 🟢 <400 lines: Direct AI usage
- 🟡 400-600 lines: Section navigation
- 🔴 >600 lines: Executive summary required

## Integration Patterns

### n8n Integration

**Server Management**: Production operations
- Startup script automation
- Configuration validation
- Health monitoring
- Restart procedures

**Workflow Development**: Custom automation
- Built-in node usage
- Custom node development (prepared)
- External service integration
- Data transformation patterns

### Development Tool Integration

**AI Assistant Tools**:
- Claude Code: Primary development and documentation
- Cursor: Code editing and pattern following
- Multi-agent coordination protocols

**Version Control**:
- GitHub Issues: Task tracking and coordination
- Pull Requests: Code review and integration
- Branch Protection: Automated workflow enforcement

### Monitoring & Observability

**Logging Pattern**: Comprehensive visibility
```bash
# Logging Structure
- Console output: Real-time development feedback
- File logging: Persistent records in n8n-data/logs/
- Error tracking: Structured error information
- Performance monitoring: Server health metrics
```

**Health Checks**: System validation
```bash
# Health Pattern
- Server availability: HTTP status checks
- Database integrity: SQLite validation
- Configuration validity: Environment variable checks
- Security compliance: Pre-commit validation
```

## Scaling Considerations

### Current Limitations
- **Single Server**: Not designed for multi-server deployment
- **SQLite Database**: May need PostgreSQL for high-volume production
- **HTTP Protocol**: HTTPS recommended for external production
- **Basic Authentication**: May need OAuth for enterprise use

### Evolution Path
- **Database Migration**: SQLite → PostgreSQL for scale
- **Multi-Server**: Horizontal scaling preparation
- **Enterprise Auth**: OAuth/SAML integration capability
- **Advanced Monitoring**: Enhanced observability and alerting

These patterns ensure consistent, secure, and maintainable development while optimizing for AI assistant collaboration and production reliability.