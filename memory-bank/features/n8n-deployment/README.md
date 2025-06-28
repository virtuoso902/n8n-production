# n8n Deployment Feature

**Purpose:** Central navigation and overview for n8n deployment feature  
**When to use:** Understanding n8n deployment setup and configuration  
**Size:** 🟢 AI-friendly (<100 lines)

## Feature Overview

Production-ready n8n workflow automation deployment with security best practices, AI-optimized development workflows, and comprehensive documentation system.

## Current Status

- **Implementation**: ✅ Complete - Server running and operational
- **Security**: ✅ Complete - Basic auth and security validation implemented  
- **Documentation**: ✅ Complete - Comprehensive documentation system
- **Automation**: ✅ Complete - Startup scripts and configuration management

## File Navigation

### Core Documentation (🟢 AI-Friendly)
- **[requirements.md](./requirements.md)** - User objectives and deployment goals
- **[decisions.md](./decisions.md)** - Key architectural and security decisions

### Detailed Specifications (🟡 Large Files)
- **[user-experience.md](./user-experience.md)** - Complete deployment and usage flow
- **[technical-design.md](./technical-design.md)** - Architecture and system design
- **[testing-strategy.md](./testing-strategy.md)** - Validation and testing approach

### Implementation Guide (🔴 Very Large Files)
- **[implementation.md](./implementation.md)** - Complete implementation details
- **[content-strategy.md](./content-strategy.md)** - Configuration and operational content

## Quick Reference

### Key Components
- **n8n Server**: v1.99.1 on localhost:5678
- **Database**: SQLite with complete workflow storage
- **Authentication**: Basic auth with secure password
- **Security**: Pre-commit validation and git compliance

### Essential Commands
```bash
./start-n8n.sh              # Start n8n server
curl -I http://localhost:5678  # Check server status
cat .env                     # View configuration
```

### Security Patterns
- Never commit .env files or credentials
- Always use feature branches (never main)
- Run security validation before all commits
- Generate secure passwords with `openssl rand -base64 32`

## Dependencies

- **Core Project**: [projectbrief.md](../../projectbrief.md)
- **Technical Foundation**: [techContext.md](../../techContext.md)
- **Security Patterns**: [systemPatterns.md](../../systemPatterns.md)
- **Development Workflows**: [CLAUDE.md](../../../CLAUDE.md)

## Key Stakeholders

- **Primary User**: Production deployment owner
- **AI Development Team**: Claude Code, Cursor, multi-agent coordination
- **Security Compliance**: Automated validation and git workflow enforcement

---

**Navigation Tip**: Start with requirements.md for objectives, then follow specific file links based on your task needs.