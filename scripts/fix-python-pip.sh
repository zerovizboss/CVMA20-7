#!/bin/bash
# Python pip Fix Script (Git Bash version)
# Repairs corrupted pip installation without full Python reinstall

echo "=== Python pip Repair Script ==="
echo ""

# Step 1: Check current Python version
echo "Step 1: Checking Python installation..."
python --version
which python
echo ""

# Step 2: Download get-pip.py
echo "Step 2: Downloading get-pip.py bootstrap script..."
curl -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py
echo "Downloaded: /tmp/get-pip.py"
echo ""

# Step 3: Reinstall pip using get-pip.py
echo "Step 3: Reinstalling pip (this will fix corrupted pip)..."
python /tmp/get-pip.py --force-reinstall --user
echo ""

# Step 4: Verify pip installation
echo "Step 4: Verifying pip installation..."
python -m pip --version
echo ""

# Step 5: Upgrade pip to latest version
echo "Step 5: Upgrading pip to latest version..."
python -m pip install --upgrade pip --user
echo ""

# Step 6: Install required packages
echo "Step 6: Installing pre-commit and dependencies..."
python -m pip install pre-commit virtualenv distlib --user
echo ""

# Step 7: Reinstall pre-commit hooks
echo "Step 7: Reinstalling pre-commit hooks..."
cd /c/Users/zerov/IdeaProjects/cvma
pre-commit uninstall
pre-commit install
echo ""

# Step 8: Verify pre-commit
echo "Step 8: Verifying pre-commit installation..."
pre-commit --version
echo ""

# Step 9: Test socket module
echo "Step 9: Testing Python socket module..."
python -c "import socket; print('Socket module: OK')"
echo ""

# Step 10: Test pre-commit hooks
echo "Step 10: Testing pre-commit hooks (empty commit)..."
git commit --allow-empty -m "Test commit to verify pre-commit hooks" || echo "Pre-commit hooks executed (commit may have been blocked by hooks)"
echo ""

echo "=== Python pip Repair Complete ==="
echo ""
echo "Next steps:"
echo "1. Test Python: python -c 'import socket; print(\"OK\")'"
echo "2. Test pip: pip --version"
echo "3. Test pre-commit: pre-commit run --all-files"
echo "4. Make a test commit without --no-verify"
echo ""
echo "If issues persist, see: docs/Technical/PRECOMMIT-HOOK-FIX-GUIDE.md"
