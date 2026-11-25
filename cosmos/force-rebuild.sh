#!/bin/sh
# Rebuild the prod server in place even though nothing changed (fresh image,
# latest PG minor, proof the rebuild path still works), or when it cannot be
# stopped cleanly. Touches only the rebuild-server resource; see rebuild.py
# and RUNBOOK.md.
#
# Needs HCLOUD_TOKEN, ARIES, ARIES_PUB, GH_PAT and the Pulumi secrets
# (cosmos/.envrc). The server boots with *this* machine's GH_PAT.
set -eu
cd "$(dirname "$0")"
STACK=prod
URN="urn:pulumi:$STACK::cosmos::command:local:Command::rebuild-server"

# --target-replace needs the resource in the state. It is not there if its
# first deploy never succeeded; then plain --target creates it instead.
if uv run pulumi stack export --stack "$STACK" | grep -qF "\"urn\": \"$URN\""; then
    target=--target-replace
else
    target=--target
fi
COSMOS_FORCE_REBUILD=1 exec uv run pulumi up --stack "$STACK" "$target" "$URN" "$@"
