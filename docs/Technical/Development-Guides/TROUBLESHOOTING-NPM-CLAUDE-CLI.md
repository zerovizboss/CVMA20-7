# Troubleshooting: npm & Claude Code CLI Issues

**Date Created**: October 21, 2025
**Session**: claude/investigate-logic-issue-011CUKU4hRcHfhVErERYTKvc
**Status**: ✅ Resolved

---

## 🔴 **Problem Summary**

### Initial Symptoms
1. **PowerShell Execution Policy Error** when running `npm` commands
2. **Claude Code CLI failing** with same error
3. **Multiple Claude Code sessions** running concurrently (duplicate branches)

### Error Messages
```powershell
npm : File C:\Program Files\nodejs\npm.ps1 cannot be loaded because running scripts
is disabled on this system. For more information, see about_Execution_Policies at
https:/go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:1
+ npm install -g npm@latest --force
+ ~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
```

```powershell
npm error code MODULE_NOT_FOUND
npm error path C:\Users\zerov\AppData\Roaming\npm\node_modules\npm\node_modules\path-scurry\package.json
npm error Cannot find module 'C:\Users\zerov\AppData\Roaming\npm\node_modules\npm\node_modules\path-scurry\dist\commonjs\index.js'
```

---

## 🔍 **Root Cause Analysis**

### What We Discovered

1. **PowerShell execution policy was NOT the issue**
   - Diagnostic showed: `Process: Bypass` (IDE terminal configured correctly)
   - No Group Policy restrictions detected

2. **npm installation was corrupted**
   - Missing module: `path-scurry/dist/commonjs/index.js`
   - npm.ps1 couldn't load because dependencies were broken

3. **Claude CLI inherited the corruption**
   - Installed via npm, so it was also broken
   - Required reinstallation after npm was fixed

### Why npm Got Corrupted

Likely causes:
- ❌ Interrupted npm update/installation
- ❌ File permission issues during global package installs
- ❌ Antivirus software quarantining npm files
- ❌ Disk issues or improper shutdown during npm operations

---

## ✅ **Diagnostic Steps**

### Step 1: Check PowerShell Execution Policy

```powershell
# Check execution policy at all scopes
Get-ExecutionPolicy -List | Format-Table -AutoSize

# Check if Group Policy is enforced
$gpPolicy = Get-ExecutionPolicy -Scope MachinePolicy
if ($gpPolicy -ne "Undefined") {
    Write-Host "WARNING: Group Policy is enforcing execution policy: $gpPolicy" -ForegroundColor Yellow
} else {
    Write-Host "No Group Policy restrictions detected." -ForegroundColor Green
}
```

**Results:**
```
        Scope ExecutionPolicy
        ----- ---------------
MachinePolicy       Undefined
   UserPolicy       Undefined
      Process          Bypass  ✅ (IDE terminal configured correctly)
  CurrentUser       Undefined
 LocalMachine       Undefined
```

### Step 2: Check Node.js/npm Status

```powershell
node --version  # v22.13.0 ✅
npm --version   # 11.4.2 (but corrupted) ❌
```

### Step 3: Identify Multiple Sessions

```bash
git branch -a
# Found 2 active Claude Code sessions:
# - claude/debug-cli-module-error-011CUKTRr9Bwg2v7wue1sRuB
# - claude/investigate-logic-issue-011CUKU4hRcHfhVErERYTKvc
```

---

## 🛠️ **Solutions Implemented**

### Fix 1: Repair npm Installation

```powershell
# Navigate to Node.js installation directory
cd "C:\Program Files\nodejs"

# Use node directly to reinstall npm
.\node.exe "C:\Program Files\nodejs\node_modules\npm\bin\npm-cli.js" install -g npm@latest
```

**Alternative (if above fails):**
```powershell
# Download Node.js installer
# https://nodejs.org/dist/v22.13.0/node-v22.13.0-x64.msi
# Run installer and choose "Repair" option
```

### Fix 2: Reinstall Claude Code CLI

```powershell
# Uninstall corrupted version
npm uninstall -g @anthropic-ai/claude-code

# Reinstall fresh version
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version  # Should show: 2.0.24 ✅
```

### Fix 3: Clean Up Duplicate Sessions

```bash
# Delete redundant local branch
git branch -d claude/debug-cli-module-error-011CUKTRr9Bwg2v7wue1sRuB

# Delete redundant remote branch (optional)
git push origin --delete claude/debug-cli-module-error-011CUKTRr9Bwg2v7wue1sRuB
```

---

## 🎯 **Verification Commands**

After repairs, verify everything is working:

```powershell
# Test npm
npm --version                    # Should show version number

# Test node
node --version                   # Should show v22.13.0

# Test Claude CLI
claude --version                 # Should show 2.0.24 or newer

# Check npm global packages
npm list -g --depth=0            # Should include @anthropic-ai/claude-code

# Check npm prefix (where globals are installed)
npm config get prefix            # Should show: C:\Users\zerov\AppData\Roaming\npm
```

---

## 🛡️ **Prevention Tips**

### Best Practices to Avoid Future Corruption

1. **Graceful Shutdowns**
   - Always close Node.js/npm processes before shutting down Windows
   - Don't force-quit PowerShell/terminals during npm operations

2. **Antivirus Exclusions**
   - Add exclusions for:
     - `C:\Program Files\nodejs\`
     - `C:\Users\zerov\AppData\Roaming\npm\`
   - Prevents quarantine of critical npm files

3. **Use `--force` Sparingly**
   - Only use `npm install --force` when absolutely necessary
   - Forces can skip integrity checks and cause corruption

4. **Regular Cache Cleaning**
   ```powershell
   # Periodically clean npm cache
   npm cache clean --force
   npm cache verify
   ```

5. **Consider PowerShell 7**
   - Already installed: `Microsoft.PowerShell 7.5.3.0`
   - Better stability and cross-platform compatibility
   - Launch with: `pwsh` instead of `powershell`

6. **Multiple Claude Sessions**
   - Close unused Claude Code terminals
   - Check active branches with: `git branch -a`
   - Each session creates a unique branch (identified by session ID)

---

## 📋 **Quick Reference Card**

### When npm Fails

```powershell
# 1. Check if it's a corruption issue
npm --version  # Error with MODULE_NOT_FOUND = corruption

# 2. Repair npm
cd "C:\Program Files\nodejs"
.\node.exe "C:\Program Files\nodejs\node_modules\npm\bin\npm-cli.js" install -g npm@latest

# 3. If that fails, repair Node.js installation
# Download: https://nodejs.org
# Run installer → Choose "Repair"
```

### When Claude CLI Fails

```powershell
# 1. Verify npm is working first
npm --version

# 2. Reinstall Claude CLI
npm uninstall -g @anthropic-ai/claude-code
npm install -g @anthropic-ai/claude-code

# 3. Verify
claude --version
```

### When PowerShell Execution Policy Blocks Scripts

```powershell
# 1. Check current policy
Get-ExecutionPolicy -List

# 2. Set for current user (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Alternative: Use Command Prompt (cmd.exe)
# npm commands work in cmd.exe without execution policy restrictions
```

---

## 📚 **Related Resources**

### Official Documentation
- [Node.js Downloads](https://nodejs.org/en/download)
- [npm Documentation](https://docs.npmjs.com/)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [PowerShell Execution Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)

### Internal CVMA Documentation
- `CLAUDE.md` - Project development guidance
- `STORM_CLAUDE.md` - Multi-agent development protocols
- `CVMA-RESOURCE-REGISTRY.md` - Persistent resource references
- `docs/Technical/Development-Guides/` - Additional development guides

---

## 🏍️ **Session Metadata**

| Attribute | Value |
|-----------|-------|
| **Session ID** | claude/investigate-logic-issue-011CUKU4hRcHfhVErERYTKvc |
| **Date** | October 21, 2025 |
| **Issue Type** | npm corruption, Claude CLI corruption, session management |
| **Time to Resolve** | ~30 minutes |
| **Final Status** | ✅ All systems operational |

### Environment Details
- **OS**: Windows (via Linux subsystem)
- **Node.js**: v22.13.0
- **npm**: 11.4.2 (after repair)
- **Claude CLI**: 2.0.24
- **PowerShell**: 7.5.3.0
- **IDE**: IntelliJ IDEA (IdeaProjects directory)

---

## 🎖️ **Success Metrics**

✅ npm reinstalled successfully
✅ Claude CLI v2.0.24 operational
✅ Duplicate sessions identified and documented for cleanup
✅ Comprehensive diagnostics documented for future reference
✅ Prevention strategies established

---

**Document maintained by**: Claude Code AI Assistant
**Last updated**: October 21, 2025
**Next review**: As needed (when similar issues occur)
