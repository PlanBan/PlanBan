@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"
title CutForge AI - Node.js
color 0B
echo.
echo     CUT FORGE AI - Node.js runtime
echo     No Python or npm install needed.
echo.
if not exist "node-server\server.mjs" (
  echo [ERROR] Please extract the whole ZIP first.
  goto :error
)
where node >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Node.js not found. Install Node.js 20 or newer:
  echo https://nodejs.org/en/download
  goto :error
)
where ffmpeg >nul 2>nul
if errorlevel 1 (
  echo [ERROR] FFmpeg missing. Install via Windows Terminal:
  echo winget install --id Gyan.FFmpeg -e
  echo After installing, close and reopen this window.
  goto :error
)
where ffprobe >nul 2>nul
if errorlevel 1 (
  echo [ERROR] FFprobe missing. Install full FFmpeg and restart.
  goto :error
)
node --check node-server\server.mjs
if errorlevel 1 (
  echo [ERROR] JavaScript syntax error.
  goto :error
)
echo.
echo [OK] Node and FFmpeg found.
echo [INFO] Starting at http://127.0.0.1:8000
start "" /min cmd /c "timeout /t 3 >nul & start http://127.0.0.1:8000"
node node-server\server.mjs
echo [INFO] Server stopped, or port 8000 already in use.
:error
echo.
pause
