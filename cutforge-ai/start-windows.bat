@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"
title CutForge AI - Windows start
color 0B

echo.
echo  ===============================================
echo       CutForge AI - launcher v0.1.1
echo  ===============================================
echo.
call :RUN
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo.
    echo  [ERROR] CutForge could not start. Error code: %RC%
    echo  Read the message above, or open WINDOWS-HELP.txt.
    echo  You can send me a screenshot of this window.
) else (
    echo.
    echo  [INFO] CutForge has stopped.
)
echo.
pause
exit /b %RC%

:RUN
if not exist "backend\app.py" (
    echo  [ERROR] Backend files not found.
    echo  Extract the ENTIRE ZIP first: right-click ZIP - Extract All.
    echo  Then open cutforge-ai\start-windows.bat in the extracted folder.
    exit /b 10
)
if not exist "frontend\index.html" (
    echo  [ERROR] The frontend folder is missing. Extract all ZIP files.
    exit /b 11
)
where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo  [ERROR] FFmpeg was not found on PATH.
    echo  1. Open Windows Terminal or PowerShell.
    echo  2. Run: winget install --id Gyan.FFmpeg -e
    echo  3. Restart Terminal and this launcher after installation.
    echo  Alternative: https://ffmpeg.org/download.html
    exit /b 20
)
where ffprobe >nul 2>nul
if errorlevel 1 (
    echo  [ERROR] FFprobe was not found on PATH. Reinstall full FFmpeg.
    exit /b 21
)
set "VENV_PY=.venv\Scripts\python.exe"
if not exist "%VENV_PY%" (
    echo  [INFO] Checking Python 3.10+ ...
    set "DETECTED_PY="
    call :FIND_PY
    if errorlevel 1 exit /b 30
    echo  [INFO] Creating virtual environment ...
    call :CREATE_VENV
    if errorlevel 1 (
        echo  [ERROR] Failed to create Python environment.
        echo  Check disk space and Python installation. Try: py -3 -m ensurepip
        exit /b 31
    )
)
"%VENV_PY%" -c "import fastapi, uvicorn, multipart, pydantic" >nul 2>nul
if errorlevel 1 (
    echo  [INFO] Installing Python libraries (first launch only) ...
    echo  [INFO] Installation details: pip-install.log
    "%VENV_PY%" -m pip install -r "backend\requirements.txt" > "pip-install.log" 2>&1
    if errorlevel 1 (
        echo  [ERROR] Could not install Python dependencies.
        echo  Check your internet connection. Log follows:
        type "pip-install.log"
        exit /b 32
    )
)
echo.
echo  [OK] Requirements are ready.
echo  [OK] Open this address: http://127.0.0.1:8000
echo  [INFO] Leave this terminal window open while editing videos.
echo  [INFO] Press Ctrl+C here to stop the server.
echo.
start "" /min "%VENV_PY%" -c "import time, webbrowser; time.sleep(3); webbrowser.open('http://127.0.0.1:8000')"
"%VENV_PY%" -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
if errorlevel 1 (
    echo  [ERROR] Server failed. Port 8000 might already be in use.
    echo  If so, check whether http://127.0.0.1:8000 already works.
    exit /b 40
)
exit /b 0

:FIND_PY
py -3 -c "import sys; assert sys.version_info >= (3,10)" >nul 2>nul
if not errorlevel 1 (
    set "DETECTED_PY=py -3"
    exit /b 0
)
python -c "import sys; assert sys.version_info >= (3,10)" >nul 2>nul
if not errorlevel 1 (
    set "DETECTED_PY=python"
    exit /b 0
)
echo  [ERROR] Python 3.10 or newer was not found.
echo  Download Python: https://www.python.org/downloads/windows/
echo  During installation enable Add python.exe to PATH, then restart.
exit /b 1

:CREATE_VENV
%DETECTED_PY% -m venv .venv
exit /b %ERRORLEVEL%
