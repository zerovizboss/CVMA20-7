# 🏍️ CVMA Git Bash Command Reference

## Quick Start
```bash
cvma-dev-start    # Start development session
cvma-overview     # Show project overview
cvma-status      # Quick project status
```

## Navigation Shortcuts
```bash
cvma             # Navigate to CVMA project directory
cvma-logs        # Navigate to logs directory
cvma-scripts     # Navigate to scripts directory
```

## Git Shortcuts
```bash
gs               # git status
ga               # git add
gc               # git commit
gp               # git push
gl               # git log --oneline -10
gb               # git branch
gco              # git checkout
```

## Salesforce Development
```bash
sf-deploy        # sf project deploy start
sf-test          # sf apex run test
sf-org           # sf org open
sf-status        # sf doctor

# CVMA-specific deployments
cvma-deploy-rsvp         # Deploy Event RSVP components
cvma-deploy-error-handler # Deploy error handler framework
```

## GitHub Project Management
```bash
cvma-sync        # Sync project board with issues
cvma-status      # Show project status
cvma-report      # Generate project status report

# Advanced functions
cvma-deploy-complete 17 "Deployment message"   # Mark issue as deployed
cvma-commit "feat: new feature" 17             # Commit with CVMA format
```

## Development Session Management
```bash
claude-session-start    # Start Claude development session
claude-session-end      # End session with summary
cvma-backup            # Create backup of important files
```

## Utility Commands
```bash
ll               # ls -la (detailed list)
mkcd dirname     # Create directory and navigate to it
findfile pattern # Search for files by name pattern
```

## Environment Variables
- `CVMA_PROJECT_DIR`: `/c/Users/zerov/IdeaProjects/cvma`
- `EDITOR`: `code` (VS Code)

## Custom Prompt Features
- Shows current user and hostname
- Displays current directory path
- Shows Git branch in red when in a Git repository
- CVMA-themed colors

## Example Workflow
```bash
# Start your development day
cvma-dev-start

# Check project status
cvma-status

# Work on code...

# Commit changes
cvma-commit "feat: implement new feature" 18

# Deploy and notify
cvma-deploy-complete 18 "Feature successfully deployed"

# Generate status report
cvma-report
```

## Configuration Files
- `~/.bashrc` - Main configuration
- `~/.bash_profile` - Profile loader
- Scripts directory: `/c/Users/zerov/IdeaProjects/cvma/scripts/`

## Pro Tips
1. **Auto-navigation**: Terminal automatically opens in CVMA project directory
2. **Session logging**: Development sessions are automatically logged
3. **Git integration**: Branch name shows in prompt
4. **Claude integration**: Special functions for Claude Code development
5. **Backup system**: Use `cvma-backup` before major changes

## Need Help?
- Type any command without arguments to see usage
- Check logs in `logs/` directory
- All scripts include help messages

---
🤖 *Generated with Claude Code for CVMA Chapter 20-7 Development*