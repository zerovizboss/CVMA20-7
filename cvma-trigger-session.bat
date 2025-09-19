@echo off
REM CVMA Session Trigger
REM Manually trigger a Claude development session
REM Created: September 9, 2025

echo.
echo 🏍️  CVMA Manual Session Trigger
echo ===============================
echo.

cd /d "C:\Users\zerov\IdeaProjects\cvma"
bash.exe -c "./scripts/cvma-session-scheduler.sh trigger"

echo.
echo Session triggered! Ready for development.
echo.

pause