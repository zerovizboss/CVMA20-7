@echo off
REM CVMA Multi-Agent System Startup
REM Quick launcher for Claude-Copilot orchestration
REM Created: September 9, 2025

echo.
echo 🤖 CVMA Multi-Agent System Startup
echo ==================================
echo.

cd /d "C:\Users\zerov\IdeaProjects\cvma"

echo 🔍 Checking system components...
bash.exe -c "./scripts/agent-orchestration/multi-agent-control-panel.sh check"

echo.
echo 🚀 Starting multi-agent system...
bash.exe -c "./scripts/agent-orchestration/multi-agent-control-panel.sh start"

echo.
echo ✅ Multi-agent system is now running!
echo.
echo Available commands:
echo   multi-agent-status.bat     - Check system status
echo   multi-agent-demo.bat       - Run demonstration
echo   multi-agent-stop.bat       - Stop all agents
echo.

pause