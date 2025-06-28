# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Core guidance for Claude Code development workflows. Start here for critical patterns.**

## 🚨 CRITICAL: Essential Patterns (READ FIRST)

### Project Context
This is a **production deployment setup for n8n** (workflow automation platform), not a source code development repository. The setup includes sophisticated AI-assisted development workflows, security practices, and documentation systems.

- **Memory-bank system**: `memory-bank/startHere.md` → all project docs
- **Use memory-bank for**: business logic, requirements, strategy
- **Use CLAUDE.md for**: dev commands, workflows, tools

### Key Components
- **n8n Server**: v1.99.1 installed globally via npm
- **Deployment Configuration**: Production-ready .env with security settings
- **Development Workflows**: Git compliance, security validation, multi-agent coordination
- **Documentation System**: Memory bank with modular feature documentation

### Git Workflow (MANDATORY)
```bash
# NEVER commit to main - always use feature branches
git checkout -b feature/issue-number-description
# Work → Security check → Commit → PR
```

### Security Validation (MANDATORY BEFORE COMMITS)
```bash
echo "🔒 Security check..."
git status --porcelain | grep "^\.env$" && echo "❌ .env staged!" && exit 1
git diff --cached | grep -E "(AIzaSy[A-Za-z0-9_-]{33}|sk-[A-Za-z0-9]{32,})" && echo "❌ API key detected!" && exit 1
echo "✅ Safe to commit"
```

### TodoWrite Usage (MANDATORY)
- Use for: 3+ step tasks, Git operations, security changes, multi-agent work
- Templates: Git workflow, Security, Multi-agent (see Templates section)
- ONE task in_progress at a time

## 📋 GitHub Issues & Development Workflow

### Essential Commands
```bash
# Issue lifecycle
gh issue list                              # Check existing
gh issue create --web                      # Create with template
gh issue view 123                          # View details
gh issue close 123 --comment "Done in PR" # Close when complete

# Automation shortcuts
./scripts/github-automation/create-issue.sh feature "Name"
./scripts/github-automation/feature-kickstart.sh [issue-number]
```

### Best Practices
- **Always reference issues in commits**: `git commit -m "Fix bug (fixes #123)"`
- **Use templates**: 🚀 Feature, ⚡ Quick Task, 🐛 Bug
- **Link to memory-bank** in issue descriptions
- **Update labels**: needs-triage → in-progress → completed

## 📋 TodoWrite Management (MANDATORY)

### Usage Rules
**MANDATORY for**: 3+ step tasks, Git operations, security changes, multi-agent work  
**Skip for**: Single tasks, <30 second work, conversations

### Core Templates
Use these standard templates (see Templates section for full definitions):
- **Git Workflow**: Git compliance → Security check → Branch → Implement → Test → PR
- **Multi-Agent**: Check work → Coordinate → Implement → Document → Validate
- **Security**: Review patterns → Secure implement → Validate → Check credentials → Test

### Enforcement
- **ONE task in_progress** at any time
- **Mark completed IMMEDIATELY** after finishing
- **NEVER mark completed** unless 100% done, tests pass, no blockers

## Essential Commands

### n8n Server Management
```bash
# Start n8n server
./start-n8n.sh

# Direct n8n commands
n8n start
n8n --version

# Check server status
curl -I http://localhost:5678
ps aux | grep n8n
```

### Configuration Management
```bash
# View current configuration
cat .env

# Generate secure password
openssl rand -base64 32

# Update password in .env
sed -i '' 's/N8N_BASIC_AUTH_PASSWORD=.*/N8N_BASIC_AUTH_PASSWORD=new_password/' .env
```

## 🚨 Git Workflow (MANDATORY - NEVER COMMIT TO MAIN)

### Standard Workflow
```bash
# 1. Check compliance (see Security section for full validation)
CURRENT_BRANCH=$(git branch --show-current)
[[ "$CURRENT_BRANCH" == "main" ]] && echo "❌ On main! Create feature branch" && exit 1

# 2. Create feature branch
git checkout main && git pull origin main
git checkout -b feature/issue-number-description

# 3. Work, security check, commit
git add .
# [Run security validation from Security section]
git commit -m "Your message (fixes #123)"

# 4. Push and create PR
git push -u origin feature/issue-number-description
gh pr create --title "Title" --body "Description"
```

### Branch Naming
- **Features**: `feature/issue-number-description`
- **Bugs**: `fix/issue-number-description`
- **Quick tasks**: `quick/issue-number-description`
- **Multi-agent**: `team/agent-name/issue-number-description`

### Branch Protection & Emergency Recovery

#### Emergency: If You Accidentally Committed to Main
```bash
# 1. IMMEDIATE: Stop and assess the situation
echo "🚨 EMERGENCY: Detected commit to main branch"
git log --oneline -5  # Review recent commits

# 2. Create feature branch from current state
EMERGENCY_BRANCH="emergency/fix-main-$(date +%s)"
git checkout -b "$EMERGENCY_BRANCH"
git checkout main && git reset --hard HEAD~1
git push --force-with-lease origin main
git checkout "$EMERGENCY_BRANCH" && git push -u origin "$EMERGENCY_BRANCH"
gh pr create --title "Emergency: Fix main commit"
echo "📝 MANDATORY: Update incident log in CLAUDE.md"

# For API keys:
git restore --staged .      # Unstage all changes
# Manually edit files to remove real credentials
# Re-stage clean files

# Step 3: Re-run security validation
# [Execute security validation commands from security section]

# Step 4: Document the incident
echo "📝 Security incident logged: $(date)" >> security-incidents.log
```

### Automated Branch Protection Validation
Agents can programmatically check and respond to protection rules:

```bash
# Check if main branch is protected
PROTECTION_STATUS=$(gh api repos/:owner/:repo/branches/main/protection 2>/dev/null && echo "protected" || echo "unprotected")

if [[ "$PROTECTION_STATUS" == "unprotected" ]]; then
  echo "⚠️ WARNING: Main branch is not protected"
  echo "📝 TODO: Repository owner should enable branch protection"
  # Agent should still follow feature branch workflow
fi

# Check required status checks
REQUIRED_CHECKS=$(gh api repos/:owner/:repo/branches/main/protection/required_status_checks 2>/dev/null)
echo "Required status checks: $REQUIRED_CHECKS"
```

## 🔒 Security Best Practices (CRITICAL)

### Environment Security Rules
**NEVER**: Commit real API keys, `.env` files, hardcoded credentials  
**ALWAYS**: Use dummy values for CI/CD, reference `.env.example`, keep `.env*` in `.gitignore`

### Pre-Commit Security Validation (MANDATORY)
**CRITICAL**: Run before every commit:
```bash
echo "🔒 Security validation..."
# Check for .env files
git status --porcelain | grep "^A.*\.env$" && echo "❌ .env staged!" && exit 1
# Check for API keys  
git diff --cached | grep -E "(AIzaSy[A-Za-z0-9_-]{33}|sk-[A-Za-z0-9]{32,})" && echo "❌ API key detected!" && exit 1
# Check for hardcoded credentials
STAGED=$(git diff --cached --name-only --diff-filter=A)
[[ -n "$STAGED" ]] && grep -E "(api_key|secret)\s*=.*['\"]" $STAGED | grep -v -E "(dummy|test)" && echo "❌ Credentials!" && exit 1
echo "✅ Safe to commit"
```

### Emergency Response
**If credentials exposed**: Revoke immediately → Clean git history → Audit systems → Update safeguards

### Data and Configuration
- **User data**: `/Users/teamlift/GitHub/N8N/n8n-data/`
- **Database**: SQLite at `n8n-data/.n8n/database.sqlite`
- **Logs**: `n8n-data/logs/`
- **Custom nodes**: `n8n-data/.n8n/nodes/` (empty, ready for development)

## Architecture and Patterns

### n8n Deployment Architecture
- **Global Installation**: n8n installed via npm globally
- **Data Persistence**: SQLite database with workflow definitions and execution history
- **Security**: Basic authentication enabled with admin user
- **Configuration**: Environment variables in `.env` file
- **Startup**: Shell script wrapper for consistent launching

### Git Workflow (MANDATORY)
- **Branch Protection**: Never commit directly to main
- **Feature Branches**: `feature/issue-number-description`
- **Security First**: Validation before every commit
- **Issue Tracking**: All work referenced to GitHub issues
- **Multi-Agent Coordination**: Team branches with agent identification

### Documentation System
- **Memory Bank**: Modular documentation in `memory-bank/`
- **Feature Documentation**: Domain-driven structure in `memory-bank/features/`
- **File Size Management**: 🟢 <400 lines, 🟡 400-600 lines, 🔴 >600 lines
- **Navigation System**: `startHere.md` for efficient context usage

### Development Patterns from Existing Rules
- **TypeScript/Next.js**: App Router pattern with src/ structure
- **Client-Side Data**: @tanstack/react-query for state management
- **API Integration**: Firebase, OpenAI, Anthropic, Replicate, Deepgram
- **Testing**: Vitest for unit tests, comprehensive coverage requirements

## 🛠️ Tool Usage Optimization

### Tool Selection Decision Tree
- **Unknown keyword/pattern**: Task tool (comprehensive search)
- **Known file path**: Read tool (direct access)
- **File patterns**: Glob tool (pattern matching)
- **Content search**: Grep tool (regex search)
- **Specific classes**: Glob tool (faster than Task)

### Performance Patterns
**CRITICAL: Always batch tool calls**
```bash
# ✅ EFFICIENT - Single message
Read: fileA.ts
Read: fileB.ts
Read: fileC.ts

# ❌ INEFFICIENT - Sequential messages
# Read fileA, then Read fileB, then Read fileC
```

### Common Workflows
**Architecture Discovery**: Read package.json → Glob configs → Read key configs  
**Feature Planning**: Grep patterns → Read components → Glob tests  
**Bug Investigation**: Grep error → Read files → Bash debug

### Best Practices
- **Read**: Use full files, batch multiple reads
- **Glob**: `**/*.{ts,tsx}` (good), `*` (too broad)
- **Grep**: Use `--include` and `--path` filters
- **Task**: For unknown searches only, not specific files

## 🤝 Multi-Agent Coordination Patterns

### Agent Identification and Coordination

#### Agent Recognition
```bash
# Check for other agents working on repository
gh pr list --state open | grep -E "(claude|gemini|cursor|copilot)" 
gh issue list --assignee "@me" --state open
gh issue list --state open | grep -E "(agent|bot|ai)"
```

#### Branch Naming for Multi-Agent Work
```bash
# Primary agent patterns:
feature/issue-number-description    # Single agent feature work
fix/issue-number-bug-description    # Single agent bug fixes
quick/issue-number-task             # Single agent quick tasks

# Multi-agent coordination patterns:
team/agent-name/issue-number-description           # Agent-specific work
team/claude/50-instruction-optimization
team/gemini/42-authentication-system
team/cursor/38-ui-improvements

# Integration branches:
integration/issue-number-multi-agent-work          # Final integration
integration/45-complete-auth-system

# Coordination branches:
coord/issue-number-planning                        # Planning phase
coord/45-auth-planning
```

### Multi-Agent Workflow Patterns

#### 1. Parallel Development Pattern
```bash
# Step 1: Agent 1 creates coordination issue
gh issue create --title "Multi-Agent: [Feature Name]" \
  --body "## Agent Assignments
  - Claude: [Specific component/task]
  - Gemini: [Specific component/task]
  - Cursor: [Specific component/task]
  
  ## Integration Points
  - [Interface/API definitions]
  - [Shared dependencies]
  
  ## Coordination Schedule
  - Phase 1: Individual development
  - Phase 2: Integration testing
  - Phase 3: Final PR creation"

# Step 2: Each agent creates their branch
git checkout -b team/claude/issue-number-my-component

# Step 3: Agents work independently with regular sync
git fetch origin
git rebase origin/main  # Keep up to date with main

# Step 4: Coordination checkpoints
gh issue comment issue-number --body "Claude: Component X completed, ready for integration"
```

#### 2. Sequential Development Pattern
```bash
# Step 1: Define work sequence in issue
# Agent 1: Foundation/architecture
# Agent 2: Core implementation  
# Agent 3: Testing and refinement

# Step 2: Each agent waits for previous to complete
while ! gh pr list --state merged | grep -q "issue-number"; do
  echo "Waiting for previous agent to complete..."
  sleep 300  # Check every 5 minutes
done

# Step 3: Create branch based on merged work
git checkout main
git pull origin main
git checkout -b team/claude/issue-number-phase-2
```

### Conflict Resolution Protocols

#### 1. Merge Conflict Resolution
```bash
# When multiple agents modify same files:

# Step 1: Detect conflict early
git fetch origin
git merge-base HEAD origin/main  # Find common ancestor
git diff HEAD origin/main  # Check for overlapping changes

# Step 2: Coordinate resolution strategy
gh issue create --title "Coordination: Merge conflict resolution needed" \
  --body "Agents: [list involved agents]
  Files: [conflicted files]
  Strategy: [proposed resolution]"

# Step 3: Designate conflict resolver (usually last to commit)
RESOLVER_AGENT="claude"  # Example designation
if [[ "$CURRENT_AGENT" == "$RESOLVER_AGENT" ]]; then
  # Resolve conflicts systematically
  git rebase origin/main
  # Handle conflicts file by file
  # Commit resolution
fi
```

#### 2. Work Overlap Prevention
```bash
# Before starting work, check for overlaps:
ISSUE_NUMBER="50"
echo "🔍 Checking for work overlaps on issue #$ISSUE_NUMBER..."

# Check existing PRs
EXISTING_PRS=$(gh pr list --search "fixes #$ISSUE_NUMBER" --state open)
if [[ -n "$EXISTING_PRS" ]]; then
  echo "⚠️ Existing PR found for this issue:"
  echo "$EXISTING_PRS"
  echo "Consider coordinating with existing work"
fi

# Check existing branches
RELATED_BRANCHES=$(git branch -r | grep -E "(issue-$ISSUE_NUMBER|$ISSUE_NUMBER-)")
if [[ -n "$RELATED_BRANCHES" ]]; then
  echo "⚠️ Related branches found:"
  echo "$RELATED_BRANCHES"
fi
```

### Communication Protocols

#### 1. Progress Updates
```bash
# Regular progress updates in issue comments
PROGRESS_MESSAGE="🤖 Claude Progress Update:
- ✅ Git workflow compliance implemented
- ✅ Security integration added
- 🔄 Multi-agent patterns in progress
- ⏳ Tool optimization pending

Next: Complete multi-agent coordination patterns"

gh issue comment issue-number --body "$PROGRESS_MESSAGE"
```

#### 2. Handoff Documentation
```bash
# When completing work for handoff to next agent
HANDOFF_MESSAGE="🤖 Claude → Next Agent Handoff:

## Completed Work
- [Detailed list of what was implemented]

## Code Locations
- \`src/components/\` - New components added
- \`src/lib/\` - Utility functions updated
- \`tests/\` - Test coverage added

## Known Issues
- [Any issues or limitations to be aware of]

## Next Steps
- [ ] [Specific tasks for next agent]
- [ ] [Integration requirements]

## Testing
- \`npm test\` - All tests passing
- \`npm run lint\` - No linting errors

Ready for next agent to continue."

gh pr comment pr-number --body "$HANDOFF_MESSAGE"
```

## 🚨 Error Recovery Procedures

### Git Issues Recovery
**Direct commit to main**:
```bash
# Create backup, reset main, move to PR
BACKUP="emergency/main-backup-$(date +%s)"
git checkout -b "$BACKUP" && git push -u origin "$BACKUP"
git checkout main && git reset --hard HEAD~1
git push --force-with-lease origin main
```

**Merge conflicts**:
```bash
git stash push -m "backup" && git fetch origin main && git rebase origin/main
# Resolve conflicts, then: git rebase --continue
git push --force-with-lease origin $(git branch --show-current)
```

**Security scan failures**:
```bash
# Remove violations
git restore --staged .env* && echo ".env*" >> .gitignore
git restore --staged . && # manually remove credentials
# Re-run security validation from Security section
```

### CI/CD Issues
**Test failures**: `npm test 2>&1 | tee test-failure.log` → fix → `npm test` → commit  
**Build failures**: `npm run typecheck && npm run lint && npm install` → `npm run build`

### Production Issues
- **Server startup failures**: Check .env configuration, verify port availability
- **Authentication issues**: Verify password in .env, check basic auth settings
- **Database issues**: Check SQLite file permissions, verify data directory

### Emergency Escalation Procedures

#### When to Escalate to Human
```bash
# Escalate immediately if:
# 1. Security credentials potentially exposed
# 2. Main branch corrupted and can't self-recover
# 3. Multiple agents in deadlock
# 4. Production system affected
# 5. Can't resolve within 3 attempts

# Escalation process:
echo "🚨 ESCALATING TO HUMAN: [Reason]"
gh issue create --title "URGENT: Human intervention needed" \
  --label "urgent" \
  --body "Situation: [Description]
  Attempted fixes: [List]
  Current state: [Status]
  Recommended action: [Suggestion]"
```

## n8n Specific Information

### Server Configuration
- **Port**: 5678 (configurable in .env)
- **Host**: 0.0.0.0 (allows external access)
- **Protocol**: HTTP (should be HTTPS for production)
- **Authentication**: Basic auth with admin user
- **Database**: SQLite (consider PostgreSQL for production)

### Data Management
- **Workflows**: Stored in SQLite database
- **Credentials**: Encrypted in database
- **Execution History**: Tracked in database
- **File Uploads**: Binary data in `n8n-data/.n8n/binaryData/`

### Production Recommendations
1. Use HTTPS (update N8N_PROTOCOL in .env)
2. Set strong passwords
3. Consider PostgreSQL for production
4. Set up proper backups of n8n-data directory
5. Configure firewall rules appropriately
6. Enable task runners (N8N_RUNNERS_ENABLED=true)

## Development Environment Context

This setup serves as a base for:
- **Custom n8n Node Development**: Use `n8n-data/.n8n/nodes/` directory
- **Workflow Development**: Create and test workflows via web UI
- **Integration Development**: Connect n8n with external systems
- **Production Deployment**: Production-ready configuration patterns

For core n8n development, clone the actual n8n repository. This setup focuses on deployment, configuration, and workflow automation rather than platform development.

## 📝 Templates & Reference

### TodoWrite Templates

#### Git Workflow Template
```json
[{"content": "Git compliance check", "status": "pending", "priority": "high", "id": "git-compliance"},
 {"content": "Pre-commit security validation", "status": "pending", "priority": "high", "id": "security-check"},
 {"content": "Create feature branch for issue #X", "status": "pending", "priority": "high", "id": "feature-branch"},
 {"content": "Implement changes", "status": "pending", "priority": "medium", "id": "implementation"},
 {"content": "Run tests and lint", "status": "pending", "priority": "medium", "id": "validation"},
 {"content": "Create PR", "status": "pending", "priority": "medium", "id": "pr-creation"}]
```

#### Multi-Agent Template
```json
[{"content": "Check existing agent work on issue #X", "status": "pending", "priority": "high", "id": "agent-coordination"},
 {"content": "Create coordination branch: team/[agent]/issue-X", "status": "pending", "priority": "high", "id": "coordination-branch"},
 {"content": "Implement assigned portion", "status": "pending", "priority": "medium", "id": "implementation"},
 {"content": "Document integration points", "status": "pending", "priority": "medium", "id": "integration-docs"},
 {"content": "Validate no conflicts", "status": "pending", "priority": "medium", "id": "conflict-check"}]
```

#### Security Template
```json
[{"content": "Review security patterns in codebase", "status": "pending", "priority": "high", "id": "security-review"},
 {"content": "Implement secure changes", "status": "pending", "priority": "high", "id": "secure-implementation"},
 {"content": "Run security validation", "status": "pending", "priority": "high", "id": "security-validation"},
 {"content": "Verify no credentials exposed", "status": "pending", "priority": "high", "id": "credential-check"},
 {"content": "Test with dummy data", "status": "pending", "priority": "medium", "id": "dummy-data-test"}]
```

### Documentation Maintenance
Update CLAUDE.md when: new patterns discovered, security procedures change, git violations occur, dev commands change.

**Update process**: Create TodoWrite task → Test patterns → Cross-reference memory-bank → Validate backward compatibility

## 🧠 Context & Memory Management

### Session Continuation
**When approaching limits**: Create TodoWrite summary → Document state in temp files → Update memory-bank if needed

### Context Priority
1. **Current task**: Active issue, branch state, modified files
2. **Dependencies**: Component patterns, test patterns, security requirements  
3. **Background**: Architecture, decisions, alternatives

### Multi-Session Tracking
**Long tasks**: Use issue comments for progress → Update labels → Create handoff docs

### State Reconstruction
```bash
# Quick context rebuild
git log --oneline -10 --author="Claude"  # Recent work
git status && git diff HEAD~1            # Current state
gh issue view $ISSUE_NUMBER --comments   # Context
ls -la *.md | grep -E "(SESSION|HANDOFF)" # Temp docs
```