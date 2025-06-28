# Project Brief: n8n Production Deployment

**Purpose:** Foundation document defining core requirements and project scope  
**When to use:** Understanding project fundamentals and decision context  
**Size:** 🟢 AI-friendly (<400 lines)

## Project Overview

This project provides a **production-ready deployment setup for n8n** (workflow automation platform) with sophisticated AI-assisted development workflows and security practices.

### Core Objectives

1. **Secure n8n Deployment**: Production-ready server configuration with security best practices
2. **AI Development Workflows**: Advanced collaboration patterns for AI assistants
3. **Compliance & Security**: Mandatory security validation and git workflow enforcement
4. **Documentation System**: Comprehensive memory bank for efficient AI context management

## Project Scope

### What This Project Includes

- **n8n Server Setup**: Global installation with production configuration
- **Security Configuration**: Basic authentication, secure password management, environment protection
- **Development Workflows**: Git compliance, branch protection, security validation
- **AI Collaboration**: Multi-agent coordination, TodoWrite management, error recovery
- **Documentation Framework**: Memory bank system following domain-driven documentation

### What This Project Does NOT Include

- **n8n Core Development**: This is deployment, not platform development
- **Custom Node Development**: Ready for custom nodes but not included by default
- **Multi-Server Deployment**: Single server production setup
- **Enterprise Features**: Community edition deployment focus

## Technology Foundation

### Core Stack
- **n8n**: v1.99.1 workflow automation platform
- **Node.js**: v23.10.0 runtime environment
- **SQLite**: Database for workflow storage
- **Shell Scripts**: Deployment automation

### Security Stack
- **Basic Authentication**: Admin user with secure password
- **Environment Variables**: Secure configuration management
- **Git Security**: Pre-commit validation, credential scanning
- **Production Patterns**: Fail-fast validation, localhost prevention

### Development Stack
- **Git Workflow**: Feature branch enforcement, never commit to main
- **GitHub Integration**: Issue tracking, PR automation, multi-agent coordination
- **AI Tools**: Claude Code, Cursor, with coordination patterns
- **Documentation**: Memory bank with file size optimization

## Success Criteria

### Primary Goals
- **Secure Operation**: Zero credential exposure, validated configurations
- **Development Efficiency**: AI assistants work effectively with documentation
- **Workflow Compliance**: All development follows security and git patterns
- **Production Readiness**: Server runs reliably with proper configurations

### Quality Metrics
- **Security Validation**: 100% commits pass security checks
- **Documentation Navigation**: 50% reduction in AI context usage
- **Workflow Compliance**: Zero direct commits to main branch
- **Server Uptime**: Reliable n8n service availability

## Project Constraints

### Technical Constraints
- **Single Server**: Local production deployment only
- **SQLite Database**: Not PostgreSQL for this deployment
- **HTTP Protocol**: HTTPS recommended for production but not required for local
- **Basic Authentication**: Not OAuth or enterprise auth

### Development Constraints
- **Security First**: All commits must pass security validation
- **Git Compliance**: Feature branch workflow mandatory
- **Documentation Standards**: Follow memory bank framework
- **AI Coordination**: Multi-agent patterns required for collaborative work

## Stakeholder Context

### Primary Stakeholder
- **Role**: Production deployment owner
- **Needs**: Secure, reliable n8n workflow automation
- **Experience**: Technical user comfortable with command line

### AI Development Team
- **Role**: Collaborative AI assistants (Claude Code, Cursor, etc.)
- **Needs**: Efficient documentation navigation, clear workflow patterns
- **Constraints**: Context limitations, coordination requirements

## Decision Framework

### Security Decisions
- **Principle**: Fail fast rather than silent fallbacks
- **Pattern**: Explicit validation with clear error messages
- **Implementation**: Pre-commit security scanning mandatory

### Development Decisions
- **Principle**: AI-first documentation and workflows
- **Pattern**: Memory bank with file size optimization
- **Implementation**: Domain-driven documentation structure

### Deployment Decisions
- **Principle**: Production-ready but local-focused
- **Pattern**: Environment variable configuration
- **Implementation**: Shell script automation with security validation

## Risk Management

### Security Risks
- **Credential Exposure**: Mitigated by pre-commit validation
- **Configuration Errors**: Mitigated by explicit validation patterns
- **Access Control**: Mitigated by basic authentication requirements

### Development Risks
- **Documentation Drift**: Mitigated by memory bank framework
- **Workflow Violations**: Mitigated by git compliance enforcement
- **AI Context Overflow**: Mitigated by file size categorization

### Operational Risks
- **Server Failures**: Mitigated by restart scripts and configuration validation
- **Data Loss**: Mitigated by backup recommendations and SQLite reliability
- **Configuration Drift**: Mitigated by environment variable patterns

This project brief serves as the foundation for all other documentation and decision-making within the n8n deployment project.