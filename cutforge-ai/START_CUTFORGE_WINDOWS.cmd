@echo off
cd /d "%~dp0"
if not exist "backend\app.py" (
    echo Please extract ALL files from ZIP before starting.
    pause
    exit /b 10
)
call "%~dp0start-windows.bat"
