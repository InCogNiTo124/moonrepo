"""Deterministic secret derivation from the single master seed.

One real secret exists (`cosmos_master_seed` in Pulumi config; a fixed
throwaway value in cosmos/local). Everything else -- PG role passwords, the
k3s cluster token, the pgBackRest cipher passphrase -- is HMAC-SHA256(seed,
label): deterministic (nothing per-credential is ever stored), one-way (a
leaked derived value reveals nothing about the seed or its siblings), and
domain-separated by label.

CLI, for when a derived value is needed by hand (e.g. sealing an app's
DB password into a SealedSecret):

    pulumi config get cosmos_master_seed | ./derive.py pg-jaja
    COSMOS_MASTER_SEED=... ./derive.py k3s-token
"""

import hashlib
import hmac
import os
import sys

# Single source of truth for app databases: each entry becomes a PG role plus
# an equally-named database it exclusively owns, reachable only from the pod
# network, password label "pg-<name>". Adding an app here is the whole story;
# kine (the k3s datastore, loopback-only) is handled separately.
PG_APPS = ["jaja", "authelia"]


def derive(seed: str, label: str) -> str:
    """Full 256-bit hex output; no truncation."""
    return hmac.new(seed.encode(), label.encode(), hashlib.sha256).hexdigest()


def pg_passwords(seed: str) -> dict[str, str]:
    return {role: derive(seed, f"pg-{role}") for role in ["kine", *PG_APPS]}


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(f"usage: {sys.argv[0]} <label>  (seed via $COSMOS_MASTER_SEED or stdin)")
    seed = os.environ.get("COSMOS_MASTER_SEED") or sys.stdin.readline().strip()
    if not seed:
        sys.exit("empty seed")
    print(derive(seed, sys.argv[1]))
