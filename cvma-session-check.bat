@echo off
REM CVMA Session Scheduler Quick Check
REM Created: September 9, 2025

echo.
echo 🏍️  CVMA Session Schedule Quick Check
echo ===================================
echo.

cd /d "C:\Users\zerov\IdeaProjects\cvma"
bash.exe -c "./scripts/cvma-session-scheduler.sh status"

echo.
echo Commands:
echo   cvma-session-check         - Check session status
echo   cvma-trigger-session       - Manually trigger session
echo   cvma-dev-start            - Begin development session
echo.

pause