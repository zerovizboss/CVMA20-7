@echo off
REM CVMA Multi-Agent System Status Check
REM Quick status viewer for agent orchestration
REM Created: September 9, 2025

echo.
echo 📊 CVMA Multi-Agent System Status
echo =================================
echo.

cd /d "C:\Users\zerov\IdeaProjects\cvma"
bash.exe -c "./scripts/agent-orchestration/multi-agent-control-panel.sh status"

echo.
pause