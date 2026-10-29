#!/usr/bin/env bash
# Start the real backend with the installed Conda environment and cached models.
set -euo pipefail
petty_backend_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../Petty_Bounty_Backend" && pwd)"
petty_backend_python="${PETTY_BACKEND_PYTHON:-/opt/anaconda3/envs/Petty_Bounty_Backend/bin/python}"
if [[ ! -x "$petty_backend_python" ]]; then
  echo 'Set PETTY_BACKEND_PYTHON to the backend environment Python.' >&2
  exit 2
fi
export AUTH_DEV_BYPASS=false
export ENABLE_UNAUTHED_ADMIN=false
export ENABLE_DEV_AUTH=false
export HF_HUB_OFFLINE="${HF_HUB_OFFLINE:-1}"
export TRANSFORMERS_OFFLINE="${TRANSFORMERS_OFFLINE:-1}"
cd "$petty_backend_root"
exec "$petty_backend_python" -m uvicorn app.main:app --host 127.0.0.1 --port 8000
