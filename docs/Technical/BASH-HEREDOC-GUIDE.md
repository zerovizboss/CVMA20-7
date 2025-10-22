# Bash Heredoc Guide

## What is Heredoc?

**Heredoc** (short for "Here Document") is a bash feature that allows you to pass multi-line text to commands without escaping special characters. It's particularly useful for generating files with complex content like XML, JSON, or multi-line commit messages.

## Why We Use Heredoc

In our CVMA development, we use heredoc for:
1. **Generating XML metadata files** - Salesforce metadata files contain many special characters
2. **Git commit messages** - Multi-line commit messages with formatting
3. **Configuration files** - Creating complex config files without escaping issues

## Basic Syntax

```bash
command << 'EOF'
line 1
line 2
line 3
EOF
```

- `<<` - Starts the heredoc
- `'EOF'` - Delimiter (can be any word, 'EOF' = End Of File is common)
- Single quotes around EOF prevent variable expansion
- Everything between the delimiters is treated as literal text

## Example: Creating XML Files

### Without Heredoc (Error-Prone):
```bash
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > file.xml
echo "<CustomMetadata xmlns=\"http://soap.sforce.com/2006/04/metadata\">" >> file.xml
echo "    <label>My Label</label>" >> file.xml
# ...many more lines with escaped quotes...
```

### With Heredoc (Clean and Safe):
```bash
cat > file.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>My Label</label>
    <protected>false</protected>
    <values>
        <field>File_Name__c</field>
        <value xsi:type="xsd:string">example.pdf</value>
    </values>
</CustomMetadata>
EOF
```

**Benefits**:
- No escaping quotes or special characters
- Readable and maintainable
- Copy-paste friendly (can paste XML directly)
- No risk of syntax errors from missing escapes

## Example: Git Commit Messages

### Our Standard Pattern:
```bash
git commit -m "$(cat <<'EOF'
📁 User Story #87 Phase 1: Google Drive Metadata Migration

## Phase 1 Complete
- 25 metadata records deployed
- 10 Bylaws files
- 15 Forms files

✅ Deploy ID: 0Afbm00000N0y0XCAR

🎖️ Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

**Why This Works**:
- `$(cat <<'EOF' ... EOF)` - Command substitution with heredoc
- Preserves all formatting (newlines, indentation, emojis)
- No escaping needed for special characters
- Clean, readable commit messages

## Example: Variable Substitution

### With Single Quotes (No Substitution):
```bash
NAME="John"
cat <<'EOF'
Hello, $NAME
EOF
```
**Output**: `Hello, $NAME` (literal)

### Without Quotes (With Substitution):
```bash
NAME="John"
cat <<EOF
Hello, $NAME
EOF
```
**Output**: `Hello, John` (variable expanded)

## CVMA Use Cases

### 1. Creating Metadata Records (create-priority-metadata.sh)
```bash
create_metadata() {
  local record_name=$1
  local label=$2
  local drive_id=$3

  cat > "src/main/default/customMetadata/${record_name}.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>${label}</label>
    <values>
        <field>Google_Drive_ID__c</field>
        <value xsi:type="xsd:string">${drive_id}</value>
    </values>
</CustomMetadata>
EOF
}
```

Note: No quotes around EOF here because we WANT variable substitution (`${label}`, `${drive_id}`)

### 2. Multi-line SQL Queries
```bash
sf data query --query "$(cat <<'EOF'
SELECT
    QualifiedApiName,
    MasterLabel,
    File_Name__c,
    Category__c
FROM CVMA_Google_Drive_File__mdt
ORDER BY Display_Order__c
EOF
)" --target-org cvma
```

### 3. Creating Documentation Files
```bash
cat > README.md << 'EOF'
# CVMA Project

## Overview
This project manages CVMA Chapter 20-7 operations.

## Features
- Member management
- Event tracking
- Document storage
EOF
```

## Common Pitfalls

### ❌ Wrong: Indented EOF Delimiter
```bash
cat << 'EOF'
    line 1
    line 2
    EOF  # This won't work - EOF must start at column 0
```

### ✅ Correct: EOF at Start of Line
```bash
cat << 'EOF'
    line 1
    line 2
EOF
```

### Alternative: Use <<- for Tabs
```bash
cat <<- 'EOF'
    line 1
    line 2
    EOF  # This works with <<- if indented with TABS (not spaces)
```

## Best Practices

1. **Use single quotes around EOF** when you don't need variable substitution
   ```bash
   cat <<'EOF'  # Recommended for most cases
   ```

2. **Choose meaningful delimiter names**
   ```bash
   cat <<'SQL'
   SELECT * FROM Account
   SQL
   ```

3. **Keep heredoc content readable** - Don't add extra indentation to the content itself

4. **Use heredoc for multi-line content** - For single lines, use regular quotes
   ```bash
   # Don't do this:
   MSG=$(cat <<'EOF'
   Single line message
   EOF
   )

   # Do this instead:
   MSG="Single line message"
   ```

## Windows Compatibility

Heredoc works in:
- ✅ Git Bash (our primary shell)
- ✅ WSL (Windows Subsystem for Linux)
- ✅ Linux/Mac native bash
- ❌ Windows CMD (not supported)
- ❌ PowerShell (uses different syntax: `@" ... "@`)

## Related Resources

- **Bash Manual**: https://www.gnu.org/software/bash/manual/html_node/Redirections.html
- **create-priority-metadata.sh**: Our script using heredoc for XML generation
- **CLAUDE.md**: Git commit protocol using heredoc for messages

## Summary

Heredoc is a **bash shell feature**, not a separate tool. It's part of bash's input/output redirection system and is incredibly useful for:
- ✅ Generating multi-line files
- ✅ Creating clean, readable scripts
- ✅ Avoiding quote escaping nightmares
- ✅ Maintaining formatting in text output

**Key Takeaway**: Whenever you need to output multi-line text in bash, think heredoc!

---

*Created: October 22, 2025*
*CVMA Chapter 20-7 Technical Documentation*
*Part of Epic #12: Google Drive MCP Integration* 🏍️
