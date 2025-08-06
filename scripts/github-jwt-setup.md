# GitHub App JWT Setup for CVMA Project Automation

## Overview
Set up a GitHub App with JWT authentication for automated project management, issue updates, and repository operations.

## Step 1: Create GitHub App

1. Go to https://github.com/settings/apps
2. Click "New GitHub App"
3. Fill in the details:

```
App name: CVMA Project Automation
Homepage URL: https://github.com/zerovizboss/CVMA20-7
Description: Automated project management for CVMA Salesforce development
```

### Required Permissions:
- **Repository permissions:**
  - Issues: Read & Write
  - Pull requests: Read & Write
  - Contents: Read & Write
  - Metadata: Read
  - Projects: Write

- **Organization permissions:**
  - Projects: Write

### Webhook Settings:
- Webhook URL: (leave empty for now)
- Webhook secret: (leave empty for now)
- SSL verification: Enable

4. Create the app and note the **App ID**

## Step 2: Generate Private Key

1. In your new GitHub App settings
2. Scroll to "Private keys" section
3. Click "Generate a private key"
4. Download the `.pem` file
5. Store securely at: `C:\Users\zerov\.ssh\cvma-github-app.pem`

## Step 3: Install App on Repository

1. In GitHub App settings, go to "Install App"
2. Select your account (zerovizboss)
3. Choose "Selected repositories"
4. Select: `CVMA20-7`
5. Click "Install"
6. Note the **Installation ID** from the URL

## Step 4: Create JWT Authentication Script

Save as `scripts/github-jwt-auth.ps1`:

```powershell
# GitHub App JWT Authentication for CVMA
param(
    [Parameter(Mandatory=$true)]
    [string]$AppId,
    
    [Parameter(Mandatory=$true)]
    [string]$PrivateKeyPath,
    
    [Parameter(Mandatory=$true)]
    [string]$InstallationId
)

# Function to create JWT
function New-GitHubAppJWT {
    param($AppId, $PrivateKeyPath)
    
    # JWT payload
    $now = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $exp = $now + 600  # 10 minutes
    
    $payload = @{
        iat = $now
        exp = $exp
        iss = $AppId
    } | ConvertTo-Json -Compress
    
    # Note: This is a simplified example
    # In production, you'd use a proper JWT library
    Write-Host "JWT creation requires additional setup with PowerShell JWT libraries"
    Write-Host "Consider using Node.js or Python for JWT generation"
}

# Function to get installation access token
function Get-InstallationToken {
    param($JWT, $InstallationId)
    
    $headers = @{
        Authorization = "Bearer $JWT"
        Accept = "application/vnd.github.v3+json"
    }
    
    $response = Invoke-RestMethod -Uri "https://api.github.com/app/installations/$InstallationId/access_tokens" -Method Post -Headers $headers
    return $response.token
}

# Main execution
Write-Host "CVMA GitHub App JWT Authentication Setup"
Write-Host "App ID: $AppId"
Write-Host "Installation ID: $InstallationId"
Write-Host "Private Key: $PrivateKeyPath"
```

## Step 5: Alternative - Use GitHub CLI with App

Create a configuration file for automated GitHub operations:

```bash
# ~/.config/gh/config.yml
git_protocol: https
editor: code
prompt: enabled
pager: less

hosts:
    github.com:
        user: cvma-automation
        oauth_token: [INSTALLATION_TOKEN]
        git_protocol: https
```

## Step 6: Automated Project Updates Script

Save as `scripts/update-project-status.ps1`:

```powershell
# CVMA Project Status Automation
param(
    [string]$IssueNumber,
    [string]$Status,  # "In Progress", "Done", etc.
    [string]$Comment
)

$repo = "zerovizboss/CVMA20-7"
$projectNumber = 5

# Update issue status
if ($Status) {
    Write-Host "Updating issue #$IssueNumber status to: $Status"
    # gh project item-edit command would go here
}

# Add comment if provided
if ($Comment) {
    Write-Host "Adding comment to issue #$IssueNumber"
    gh issue comment $IssueNumber --repo $repo --body $Comment
}

# Update project board
gh project item-list $projectNumber --owner zerovizboss | Where-Object { $_ -match "#$IssueNumber" } | ForEach-Object {
    Write-Host "Found issue on project board: $_"
    # Update project status logic here
}
```

## Quick Setup Recommendation

**For immediate use, I recommend:**

1. **Keep current PAT setup** for now (it's working well)
2. **Set token expiration reminder** in your calendar
3. **Create the automation scripts** using current auth
4. **Upgrade to GitHub App later** when you need more advanced automation

Would you like me to:
1. **Create the automation scripts using your current PAT?**
2. **Walk through the GitHub App setup step-by-step?**
3. **Set up a hybrid approach?**

## Current Working Solution

Since your current authentication is working perfectly, we can create automated scripts right now:

```powershell
# Daily project sync script
.\scripts\sync-project-board.ps1

# Automatic issue updates when code is deployed
.\scripts\auto-close-completed-stories.ps1

# Weekly project status report
.\scripts\generate-project-report.ps1
```

What would you prefer to set up first?