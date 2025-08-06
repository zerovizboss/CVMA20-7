# CVMA Claude Usage Tracking Script
# Usage: .\CVMA-Usage-Tracker.ps1 -Action [start|task|end] -TaskType [type] -Description [desc] -EstimatedTokens [number]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "task", "end", "report")]
    [string]$Action,
    
    [ValidateSet("code_generation", "code_review", "documentation", "testing", "deployment", "analysis", "debugging")]
    [string]$TaskType = "",
    
    [string]$Description = "",
    
    [int]$EstimatedTokens = 0,
    
    [string]$Epic = "",
    
    [string]$UserStory = ""
)

# File paths
$LogDir = "$PSScriptRoot\..\..\logs"
$LogFile = "$LogDir\claude-usage.json"
$SessionFile = "$LogDir\current-session.json"

# Ensure log directory exists
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Token cost rates (Claude 3.5 Sonnet - January 2025)
$INPUT_RATE = 0.003 / 1000   # $3 per 1M input tokens
$OUTPUT_RATE = 0.015 / 1000  # $15 per 1M output tokens

# Task type token estimates
$TaskTypeEstimates = @{
    "code_generation" = 5000
    "code_review" = 3000
    "documentation" = 4000
    "testing" = 3500
    "deployment" = 2000
    "analysis" = 2500
    "debugging" = 4500
}

function Start-Session {
    $sessionId = "cvma-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
    $session = @{
        session_id = $sessionId
        start_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        date = Get-Date -Format "yyyy-MM-dd"
        epic = $Epic
        user_story = $UserStory
        tasks = @()
        total_estimated_tokens = 0
        estimated_input_tokens = 0
        estimated_output_tokens = 0
        estimated_cost = 0.0
    }
    
    $session | ConvertTo-Json -Depth 3 | Out-File $SessionFile -Encoding UTF8
    
    Write-Host "🚀 Started Claude session: $sessionId" -ForegroundColor Green
    if ($Epic) { Write-Host "   Epic: $Epic" -ForegroundColor Cyan }
    if ($UserStory) { Write-Host "   User Story: $UserStory" -ForegroundColor Cyan }
    Write-Host "   Start time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
}

function Add-Task {
    param($Type, $Desc, $Tokens)
    
    if (-not (Test-Path $SessionFile)) {
        Write-Host "❌ No active session. Use 'start' first." -ForegroundColor Red
        return
    }
    
    $session = Get-Content $SessionFile -Encoding UTF8 | ConvertFrom-Json
    
    # Use provided tokens or estimate based on task type
    if ($Tokens -eq 0 -and $TaskTypeEstimates.ContainsKey($Type)) {
        $Tokens = $TaskTypeEstimates[$Type]
    }
    
    $task = @{
        type = $Type
        description = $Desc
        estimated_tokens = $Tokens
        timestamp = Get-Date -Format "HH:mm:ss"
    }
    
    # Convert to array if needed
    if ($session.tasks -is [System.Object]) {
        $session.tasks = @($session.tasks)
    }
    $session.tasks += $task
    $session.total_estimated_tokens += $Tokens
    
    # Estimate input/output distribution (60% input, 40% output)
    $session.estimated_input_tokens = [math]::Round($session.total_estimated_tokens * 0.6)
    $session.estimated_output_tokens = [math]::Round($session.total_estimated_tokens * 0.4)
    
    # Calculate estimated cost
    $session.estimated_cost = [math]::Round(
        ($session.estimated_input_tokens * $INPUT_RATE) + 
        ($session.estimated_output_tokens * $OUTPUT_RATE), 4
    )
    
    $session | ConvertTo-Json -Depth 3 | Out-File $SessionFile -Encoding UTF8
    
    Write-Host "✅ Added task: $Desc" -ForegroundColor Green
    Write-Host "   Type: $Type | Tokens: $Tokens | Running cost: `$$($session.estimated_cost)" -ForegroundColor Gray
}

function End-Session {
    if (-not (Test-Path $SessionFile)) {
        Write-Host "❌ No active session to end." -ForegroundColor Red
        return
    }
    
    $session = Get-Content $SessionFile -Encoding UTF8 | ConvertFrom-Json
    $session.end_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Calculate duration
    $start = [datetime]$session.start_time
    $end = [datetime]$session.end_time
    $session.duration_minutes = [math]::Round(($end - $start).TotalMinutes, 2)
    
    # Calculate efficiency metrics
    $session.tasks_per_hour = if ($session.duration_minutes -gt 0) { 
        [math]::Round(($session.tasks.Count / ($session.duration_minutes / 60)), 2) 
    } else { 0 }
    
    $session.cost_per_task = if ($session.tasks.Count -gt 0) { 
        [math]::Round($session.estimated_cost / $session.tasks.Count, 4) 
    } else { 0 }
    
    # Load existing log or create new
    $log = @()
    if (Test-Path $LogFile) {
        $existingLog = Get-Content $LogFile -Encoding UTF8 | ConvertFrom-Json
        if ($existingLog -is [System.Array]) {
            $log = @($existingLog)
        } else {
            $log = @($existingLog)
        }
    }
    
    $log += $session
    $log | ConvertTo-Json -Depth 4 | Out-File $LogFile -Encoding UTF8
    
    Remove-Item $SessionFile
    
    Write-Host "🏁 Session ended: $($session.session_id)" -ForegroundColor Green
    Write-Host "   Duration: $($session.duration_minutes) minutes" -ForegroundColor Gray
    Write-Host "   Tasks completed: $($session.tasks.Count)" -ForegroundColor Gray
    Write-Host "   Estimated cost: `$$($session.estimated_cost)" -ForegroundColor Yellow
    Write-Host "   Tasks per hour: $($session.tasks_per_hour)" -ForegroundColor Gray
    Write-Host "   Cost per task: `$$($session.cost_per_task)" -ForegroundColor Gray
}

function Show-Report {
    if (-not (Test-Path $LogFile)) {
        Write-Host "📊 No usage data available yet." -ForegroundColor Yellow
        return
    }
    
    $log = Get-Content $LogFile -Encoding UTF8 | ConvertFrom-Json
    if ($log -isnot [System.Array]) {
        $log = @($log)
    }
    
    # Calculate totals
    $totalSessions = $log.Count
    $totalCost = ($log | Measure-Object -Property estimated_cost -Sum).Sum
    $totalTokens = ($log | Measure-Object -Property total_estimated_tokens -Sum).Sum
    $avgCostPerSession = if ($totalSessions -gt 0) { $totalCost / $totalSessions } else { 0 }
    
    # Recent sessions (last 7 days)
    $recentSessions = $log | Where-Object { 
        $sessionDate = [datetime]$_.date
        $sessionDate -ge (Get-Date).AddDays(-7)
    }
    
    $weeklyCost = ($recentSessions | Measure-Object -Property estimated_cost -Sum).Sum
    
    # Task type analysis
    $allTasks = $log | ForEach-Object { $_.tasks } | Where-Object { $_ }
    $taskStats = $allTasks | Group-Object -Property type | Sort-Object Count -Descending
    
    Write-Host "📊 CVMA Claude Usage Report" -ForegroundColor Cyan
    Write-Host "=" * 40 -ForegroundColor Cyan
    Write-Host "📈 Overall Statistics:" -ForegroundColor White
    Write-Host "   Total Sessions: $totalSessions" -ForegroundColor Gray
    Write-Host "   Total Cost: `$$([math]::Round($totalCost, 2))" -ForegroundColor Yellow
    Write-Host "   Total Tokens: $([math]::Round($totalTokens / 1000, 1))K" -ForegroundColor Gray
    Write-Host "   Avg Cost/Session: `$$([math]::Round($avgCostPerSession, 2))" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📅 Last 7 Days:" -ForegroundColor White
    Write-Host "   Sessions: $($recentSessions.Count)" -ForegroundColor Gray
    Write-Host "   Weekly Cost: `$$([math]::Round($weeklyCost, 2))" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔧 Task Type Breakdown:" -ForegroundColor White
    foreach ($taskType in $taskStats) {
        $avgTokens = ($allTasks | Where-Object { $_.type -eq $taskType.Name } | Measure-Object -Property estimated_tokens -Average).Average
        Write-Host "   $($taskType.Name): $($taskType.Count) tasks | Avg: $([math]::Round($avgTokens, 0)) tokens" -ForegroundColor Gray
    }
    
    # Show recent sessions
    Write-Host ""
    Write-Host "🕒 Recent Sessions:" -ForegroundColor White
    $recentSessions | Select-Object -Last 5 | ForEach-Object {
        Write-Host "   $($_.date) $($_.session_id.Split('-')[-1]) | $($_.tasks.Count) tasks | `$$($_.estimated_cost)" -ForegroundColor Gray
    }
}

# Main execution
switch ($Action) {
    "start" { 
        Start-Session 
    }
    "task" { 
        if (-not $TaskType -or -not $Description) {
            Write-Host "❌ TaskType and Description are required for 'task' action." -ForegroundColor Red
            exit 1
        }
        Add-Task -Type $TaskType -Desc $Description -Tokens $EstimatedTokens 
    }
    "end" { 
        End-Session 
    }
    "report" { 
        Show-Report 
    }
}