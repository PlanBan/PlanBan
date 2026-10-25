#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v node >/dev/null || { echo 'Install Node.js >=20'; exit 1; }
command -v ffmpeg >/dev/null || { echo 'Install FFmpeg'; exit 1; }
command -v ffprobe >/dev/null || { echo 'Install ffprobe'; exit 1; }
node node-server/server.mjs
