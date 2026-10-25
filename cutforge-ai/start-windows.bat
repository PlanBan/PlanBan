@echo off
setlocal
cd /d "%~dp0"
where ffmpeg >nul 2>nul
if errorlevel 1 (
  echo [CutForge] ERROR: FFmpeg not found. Install FFmpeg and add it to PATH.
  pause
  exit /b 1
)
if not exist .venv\Scripts\python.exe (
  py -3 -m venv .venv
  if errorlevel 1 (echo Python 3.10+ is required & pause & exit /b 1)
)
call .venv\Scripts\activate.bat
python -m pip install -r backend\requirements.txt
if errorlevel 1 (echo Dependencies failed & pause & exit /b 1)
echo.
echo Open http://127.0.0.1:8000 in your browser
python -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
pause
