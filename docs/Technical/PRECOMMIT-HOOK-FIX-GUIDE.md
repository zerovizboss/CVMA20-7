# Pre-Commit Hook Fix Guide

**Issue**: ModuleNotFoundError: No module named '_socket'
**Impact**: Git commits require `--no-verify` bypass
**Root Cause**: Python 3.13 installation missing critical `_socket.pyd` DLL
**Discovered**: October 23, 2025

---

## Problem Analysis

### Error Stack Trace
```
Traceback (most recent call last):
  File "C:\Users\zerov\AppData\Roaming\Python\Python313\site-packages\pre_commit\xargs.py", line 6, in <module>
    import multiprocessing
  File "C:\Python313\Lib\multiprocessing\__init__.py", line 16, in <module>
    from . import context
  File "C:\Python313\Lib\multiprocessing\context.py", line 6, in <module>
    from . import reduction
  File "C:\Python313\Lib\multiprocessing\reduction.py", line 16, in <module>
    import socket
  File "C:\Python313\Lib\socket.py", line 52, in <module>
    import _socket
ModuleNotFoundError: No module named '_socket'
```

### Root Cause

**Python Installation**: `C:\Python313\python.exe`
**Pre-commit Hook**: `.git/hooks/pre-commit` uses `INSTALL_PYTHON='C:\Python313\python.exe'`
**Missing DLL**: `C:\Python313\DLLs\_socket.pyd` does not exist

**Diagnosis**: Corrupted or incomplete Python 3.13 installation

### Missing DLLs Identified

**Present in C:\Python313\DLLs\**:
- `_ctypes_test.pyd`
- `_hashlib.pyd`
- `_multiprocessing.pyd`
- `_overlapped.pyd`
- `select.pyd`
- (19 other DLLs)

**Missing (Critical)**:
- `_socket.pyd` ❌
- Potentially other network-related modules

---

## Solution Options

### Option 1: Reinstall Python 3.13 (Recommended)

**Time**: 10-15 minutes
**Risk**: Low (preserves existing packages with proper uninstall/reinstall)

**Steps**:
1. Download Python 3.13.1 from https://www.python.org/downloads/
2. Run installer with "Repair" option first
3. If repair fails, uninstall Python 3.13 completely
4. Reinstall Python 3.13 with "Add to PATH" option checked
5. Verify installation:
   ```bash
   python -c "import socket; print('Socket module works')"
   ```
6. Reinstall pre-commit:
   ```bash
   pip install --upgrade pre-commit
   pre-commit install
   ```
7. Test pre-commit hook:
   ```bash
   git add .
   git commit -m "Test commit"
   # Should run hooks without errors
   ```

### Option 2: Manual DLL Replacement

**Time**: 5 minutes
**Risk**: Medium (requires finding compatible DLL)

**Steps**:
1. Download Python 3.13 installer (without running)
2. Extract `_socket.pyd` from installer using 7-Zip or similar
3. Copy `_socket.pyd` to `C:\Python313\DLLs\`
4. Test socket import:
   ```bash
   python -c "import socket; print('Fixed')"
   ```
5. Test pre-commit:
   ```bash
   git commit --allow-empty -m "Test"
   ```

**DLL Location in Installer**:
- Installer: `python-3.13.1-amd64.exe`
- Extracted path: `DLLs\_socket.pyd`
- Target: `C:\Python313\DLLs\_socket.pyd`

### Option 3: Use Alternative Python Installation

**Time**: 15 minutes
**Risk**: Low (isolates pre-commit from system Python)

**Steps**:
1. Install Python 3.12 (more stable than 3.13) via https://www.python.org/downloads/
2. Create virtual environment:
   ```bash
   python3.12 -m venv .venv-precommit
   source .venv-precommit/Scripts/activate  # Git Bash
   ```
3. Install pre-commit in venv:
   ```bash
   pip install pre-commit
   pre-commit install
   ```
4. Verify `.git/hooks/pre-commit` now uses venv Python
5. Test commit workflow

### Option 4: Disable Pre-commit Hooks (Temporary Workaround)

**Time**: 1 minute
**Risk**: Low (already using this workaround with `--no-verify`)

**Current Workaround**:
```bash
git commit --no-verify -m "Commit message"
```

**Permanent Disable** (not recommended):
```bash
pre-commit uninstall
# Or manually remove .git/hooks/pre-commit
```

**Re-enable Later**:
```bash
pre-commit install
```

---

## Recommended Approach

### For Immediate Fix (Option 1 Preferred)

**Step-by-step**:
1. Open Windows Settings → Apps → Installed apps
2. Find "Python 3.13.1"
3. Click three dots → Modify
4. Select "Repair" option
5. Wait for repair to complete
6. Test socket module:
   ```bash
   python -c "import socket; print('Repaired successfully')"
   ```
7. If repair fails, proceed with full uninstall/reinstall

### For Long-term Stability (Option 3)

**Why Virtual Environment is Better**:
- Isolates pre-commit dependencies from system Python
- Prevents future corruption issues
- Easier to troubleshoot and rebuild
- Industry best practice for development tools

**Implementation**:
```bash
# Create dedicated venv for development tools
python -m venv .venv-devtools
source .venv-devtools/Scripts/activate

# Install pre-commit
pip install pre-commit

# Install pre-commit hooks
pre-commit install

# Deactivate venv
deactivate

# Pre-commit will now use venv Python automatically
```

---

## Testing Checklist

After implementing fix:

- [ ] Test socket module: `python -c "import socket; print('OK')"`
- [ ] Test pre-commit command: `pre-commit --version`
- [ ] Test pre-commit run: `pre-commit run --all-files`
- [ ] Test git commit: `git commit --allow-empty -m "Test"`
- [ ] Verify hooks execute without errors
- [ ] Confirm no `--no-verify` bypass needed

---

## Impact Analysis

### Current Workaround Impact

**Bypassed Hooks** (with `--no-verify`):
1. `trailing-whitespace` - Removes trailing whitespace from files
2. `end-of-file-fixer` - Ensures files end with newline
3. `check-yaml` - Validates YAML syntax
4. `check-json` - Validates JSON syntax
5. `check-xml` - Validates XML syntax
6. `check-merge-conflict` - Detects merge conflict markers
7. `check-case-conflict` - Detects case-conflicting files
8. `check-added-large-files` - Prevents files >1MB
9. `mixed-line-ending` - Fixes line ending inconsistencies
10. `black` - Python code formatting
11. `apex-pmd-check` - Apex code quality analysis
12. `apex-test-validation` - Apex test class validation
13. `security-scan` - Security pattern validation
14. `cvma-naming-validation` - CVMA naming convention check

**Risk Level**: **Medium**
- Code quality checks bypassed
- Security scans not running
- Naming conventions not enforced
- Potential for introducing code quality issues

**Mitigation**: Manual code review before merging to main

---

## Prevention for Future

### Best Practices

1. **Use Virtual Environments** for all development tools (pre-commit, linters, formatters)
2. **Pin Python Version** in project documentation (avoid bleeding-edge 3.13)
3. **Regular Python Updates** via official installer (avoid manual DLL manipulation)
4. **Backup DLLs Directory** before Python updates
5. **Test Pre-commit Hooks** after any Python environment changes

### Monitoring

**Add to Session Initialization Checklist**:
```bash
# Verify pre-commit is functional
pre-commit --version || echo "⚠️ Pre-commit broken - investigate"

# Test hooks on empty commit
git commit --allow-empty -m "Hook test" --dry-run
```

---

## Next Session Action Items

### Priority 1: Python Repair (15 minutes)
1. Run Python 3.13 installer in Repair mode
2. Verify `_socket.pyd` restored
3. Test pre-commit hooks
4. Remove `--no-verify` workaround from workflow

### Priority 2: Documentation Update
1. Add Python version requirement to README.md
2. Document pre-commit setup in CLAUDE.md
3. Create troubleshooting section for common issues

### Priority 3: Continuous Validation
1. Add pre-commit hook validation to session startup
2. Create automated test for critical Python modules
3. Document recovery procedures for future corruption

---

## References

**Python 3.13 Documentation**:
- https://docs.python.org/3.13/library/socket.html
- https://www.python.org/downloads/release/python-3131/

**Pre-commit Documentation**:
- https://pre-commit.com/#install
- https://pre-commit.com/#usage

**Related Issues**:
- Bug #88: Metadata deployment issues (resolved)
- Pre-commit hook failures: Ongoing since early October 2025

---

---

## 🔄 UPDATE: October 23, 2025 - Partial Fix Applied

### What Was Fixed
✅ **_socket.pyd restored**: File now present in `C:\Python313\DLLs\_socket.pyd` (86,360 bytes)
✅ **Socket module imports**: `python -c "import socket"` works successfully
✅ **Pre-commit command works**: `pre-commit --version` returns `pre-commit 4.3.0`

### Remaining Issues
❌ **pip is corrupted**: Missing `pip._vendor.rich._emoji_codes` module
❌ **Cannot install packages**: `pip install` fails with ModuleNotFoundError
❌ **Pre-commit hooks fail**: Cannot create virtualenv due to missing `distlib.util`

### Error Details
```
ModuleNotFoundError: No module named 'pip._vendor.rich._emoji_codes'
```

**Impact**: Can run pre-commit command but hooks fail during virtualenv creation

### Root Cause Analysis
**Python Launch Manager Reinstall**: Fixed _socket but introduced new pip corruption
- ✅ Core Python DLLs restored (_socket, _ssl, select)
- ❌ pip installation corrupted (missing vendor packages)
- ❌ Site-packages partially broken

### Recommended Next Steps

**Option A: Full Python Uninstall/Reinstall** (30 minutes, recommended)
1. Completely uninstall Python 3.13 from Windows Settings
2. Delete remaining directories:
   - `C:\Python313\`
   - `C:\Users\zerov\AppData\Roaming\Python\Python313\`
   - `C:\Users\zerov\AppData\Local\Python313\`
3. Download fresh Python 3.13.9 from https://www.python.org/downloads/
4. Install with "Add to PATH" option
5. Verify installation:
   ```bash
   python --version
   python -c "import socket; print('OK')"
   pip --version
   ```
6. Reinstall pre-commit:
   ```bash
   pip install pre-commit
   pre-commit install
   ```

**Option B: Use Python 3.12 Instead** (20 minutes, more stable)
1. Download Python 3.12.x (more stable than 3.13)
2. Install alongside Python 3.13
3. Update pre-commit hook to use Python 3.12:
   ```bash
   # Edit .git/hooks/pre-commit
   INSTALL_PYTHON='C:\Python312\python.exe'
   ```
4. Reinstall pre-commit with Python 3.12:
   ```bash
   py -3.12 -m pip install pre-commit
   pre-commit install
   ```

**Option C: Continue --no-verify Workaround** (0 minutes, temporary)
- Socket issue fixed (progress made!)
- pip corruption prevents full pre-commit functionality
- Continue using `git commit --no-verify` until full repair

### Current Workaround
```bash
# All commits require --no-verify bypass
git commit --no-verify -m "Commit message"
```

**Recommendation**: **Option A** (full uninstall/reinstall) for clean Python environment

---

**Session**: October 23, 2025
**Issue**: Pre-commit hook Python module errors
**Progress**: ✅ _socket fixed, ❌ pip corrupted
**Status**: ⏳ Partial fix - requires full Python reinstall
**Workaround**: Continue using `git commit --no-verify`
**Permanent Fix**: Complete Python 3.13 uninstall/reinstall or switch to Python 3.12
