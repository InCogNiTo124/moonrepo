#!/usr/bin/env bash
# Idempotently start the host-side services the VM depends on:
#   - the read-only git server (ArgoCD's repo source), port 8930
#   - a docker registry for locally built images, port 5000
# (pgBackRest talks to real Hetzner Object Storage -- the dev stack's own
# bucket -- so there is no local S3 stand-in to run.)
set -euo pipefail
cd "$(dirname "$0")"

if docker inspect cosmos-local-registry >/dev/null 2>&1; then
  docker start cosmos-local-registry >/dev/null
else
  docker run -d --name cosmos-local-registry --restart unless-stopped \
    -p 5000:5000 registry:2 >/dev/null
fi
echo "registry: running on :5000"

if pgrep -f "python.*git_server.py" >/dev/null; then
  echo "git server: already running on :8930"
else
  # setsid: fully detach so the git server outlives the invoking session
  setsid nohup python3 git_server.py >>/tmp/cosmos-local-git-server.log 2>&1 &
  echo "git server: started on :8930 (log: /tmp/cosmos-local-git-server.log)"
fi
