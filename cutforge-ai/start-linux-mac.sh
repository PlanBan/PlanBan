#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v ffmpeg >/dev/null || { echo "Install FFmpeg first" >&2; exit 1; }
command -v ffprobe >/dev/null || { echo "Install FFprobe first" >&2; exit 1; }
python3 -m venv .venv
. .venv/bin/activate
python -m pip install -r backend/requirements.txt
echo "Open http://127.0.0.1:8000 in your browser"
python -m uvicorn backend.app:app --host 127.0.0.1 --port 8000
