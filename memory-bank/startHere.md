# Memory Bank Navigation Hub

**Purpose:** Primary entry point for AI assistants working on the n8n deployment project  
**When to use:** Start here for comprehensive project context and efficient navigation  
**Quick sections:** Project overview, task-specific paths, file size guide  
**Size:** 🟢 AI-friendly (<400 lines)

## Project Overview

This is a **production-ready n8n workflow automation deployment** with sophisticated AI-assisted development workflows. The project combines:

- **n8n Server**: Production deployment setup with security configurations
- **Development Workflows**: Git compliance, security validation, multi-agent coordination  
- **Documentation System**: Memory bank with modular feature documentation
- **AI Development**: Advanced AI assistant collaboration patterns

## How to Navigate This Documentation

### File Size Categorization System

All files are categorized for optimal AI context usage:

```
🟢 AI-Friendly Files (<400 lines)
- Use directly in AI context
- Combine multiple related files
- Safe for full content loading

🟡 Large Files (400-600 lines)  
- Start with executive summary
- Use specific sections by ## headers
- Load selectively by task needs

🔴 Very Large Files (>600 lines)
- ALWAYS start with executive summary
- Section-based navigation required
- Use startHere.md paths for efficiency
```

### Primary Navigation Paths

#### Working with n8n Server
```
1. startHere.md (this file)
2. productContext.md (why this deployment exists)
3. features/n8n-deployment/README.md (deployment overview)
4. features/n8n-deployment/technical-design.md → "## Server Configuration"
```

#### Security & Compliance Work
```
1. CLAUDE.md → "## Security Best Practices"
2. features/security-workflows/README.md (security patterns)
3. techContext.md → "## Security Architecture"
```

#### Development Workflow Tasks
```
1. CLAUDE.md → "## Git Workflow"
2. features/ai-development-workflows/README.md (workflow patterns)
3. systemPatterns.md → "## Development Patterns"
```

#### Documentation & Memory Bank Work
```
1. guides/documentation-framework.md (this framework)
2. AI_GUIDE.md (AI optimization patterns)
3. features/documentation-system/README.md (system overview)
```

## Directory Structure Guide

```
memory-bank/
├── startHere.md                    # 🎯 This file - start here
├── AI_GUIDE.md                     # 🤖 AI optimization guide
├── projectbrief.md                 # 🟢 Project foundation
├── productContext.md               # 🟢 Why this project exists
├── activeContext.md                # 🟢 Current work focus
├── systemPatterns.md               # 🟢 Architecture patterns
├── techContext.md                  # 🟢 Technology stack
├── progress.md                     # 🟢 Current status
├── guides/
│   ├── documentation-framework.md  # 📚 Documentation standards
│   └── executive-summaries.md      # 📋 Large file summaries
└── features/
    ├── n8n-deployment/            # 🔴 Main deployment feature
    ├── security-workflows/        # 🟡 Security patterns
    ├── ai-development-workflows/  # 🟡 AI collaboration
    └── documentation-system/      # 🟢 Memory bank system
```

## Performance Guidelines

### Efficient AI Usage (✅ Do This)
- Start with startHere.md for full memory bank loads
- Use executive summaries first for 🔴 files  
- Search by section headers (`## Section Name`)
- Combine related 🟢 files together
- Follow task-specific navigation paths

### Inefficient AI Usage (❌ Avoid This)  
- Loading multiple complete 🔴 files
- Using line numbers instead of section headers
- Mixing unrelated documentation
- Ignoring file size indicators
- Skipping navigation guidance

## Current Project Status

**Phase:** Production Deployment Active  
**n8n Version:** 1.99.1  
**Server Status:** Running on localhost:5678  
**Security:** Basic auth enabled with secure password  
**Git Workflow:** Feature branch workflow enforced  
**Documentation:** Memory bank system implemented

## Key Stakeholders

- **Primary User:** Production n8n deployment owner
- **AI Assistants:** Claude Code, Cursor, other AI development tools
- **Development Focus:** Security, workflow automation, AI collaboration

## Quick Reference

- **Start n8n:** `./start-n8n.sh`
- **Security check:** See CLAUDE.md security validation section
- **Git workflow:** Never commit to main, always use feature branches
- **Documentation:** Follow guides/documentation-framework.md standards

---

**Next Steps:** Choose a task-specific navigation path above, or read productContext.md for comprehensive project understanding.