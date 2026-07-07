#!/usr/bin/env bash
# "Deploy" the current working copy to the local cluster: snapshot it (jj does
# this implicitly) and point the `dev` bookmark at it. ArgoCD in the VM polls
# the git server every 60s and syncs whatever `dev` points to.
set -euo pipefail
jj bookmark set dev -r @ --allow-backwards
echo "dev -> $(jj log -r @ --no-graph -T 'commit_id.short()') ; ArgoCD will sync within ~60s"
