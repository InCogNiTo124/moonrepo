"""Rebuild the prod server in place via Hetzner's "rebuild" action.

Run by the `rebuild-server` Pulumi resource (see __main__.py), never by hand:
`pulumi up` runs it when the cloud-init template or the image changes, and
`./force-rebuild.sh` runs it when nothing changed.

Rebuild reinstalls the image on the *same* server with new user data, so it
never needs fresh capacity -- the server keeps its id, IP, type and the
attached data volume. Replacing the server instead means releasing the slot
and hoping Hetzner has another one (2026-08-20: it did not).

Input:
  stdin                 the rendered cloud-init (secret, never printed)
  COSMOS_SERVER_ID      Hetzner server id
  COSMOS_SERVER_IP      address to ssh to
  COSMOS_IMAGE          image (name or id) to rebuild from
  HCLOUD_TOKEN, ARIES   API token, ssh private key (process environment)
  COSMOS_FORCE_REBUILD  set to 1 to rebuild even if the server already runs
                        this exact cloud-init and image, or cannot be stopped
                        cleanly

Safe to re-run: unless forced, a server that already booted from this
cloud-init on this image is only verified, not rebuilt.
"""

import hashlib
import http.client
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

API = os.environ.get("HCLOUD_ENDPOINT", "https://api.hetzner.cloud/v1")
USER_DATA_PATH = "/var/lib/cloud/instance/user-data.txt"
USER_DATA_LIMIT = 32 * 1024

# Shared with the server's delete hook in __main__.py. k3s goes first -- it is
# Postgres' client. `systemctl stop k3s` leaves the pods running, so
# k3s-killall.sh ends them: they hold connections to Postgres and files on
# /data. Backups in flight are stopped too, not just their timers. Exits 1 if
# Postgres is still up: nothing may wipe or detach its disk while it runs.
STOP_SERVICES = """\
systemctl stop k3s
if [ -x /usr/local/bin/k3s-killall.sh ]; then /usr/local/bin/k3s-killall.sh >/dev/null 2>&1; fi
systemctl stop pgbackrest-full.timer pgbackrest-diff.timer
systemctl stop pgbackrest-full.service pgbackrest-diff.service
systemctl stop 'postgresql@*'
for _ in $(seq 30); do pgrep -x postgres >/dev/null || break; sleep 1; done
if pgrep -x postgres >/dev/null; then echo 'postgres is still running' >&2; exit 1; fi
sync
"""

# A failed umount is survivable once Postgres is down and the disk is synced
# (ext4 journal); the rebuild powers the server off right after.
GRACEFUL_STOP = STOP_SERVICES + (
    "umount /data || echo 'WARNING: /data did not unmount, relying on sync'\n"
)

SSH_WAIT = 300  # a freshly created server is still booting
SSH_WAIT_FORCED = 30  # forced: do not wait long for a server that may be dead
ACTION_WAIT = 600  # one Hetzner action (rebuild, poweron)
CLOUD_INIT_WAIT = 1500  # full cloud-init run on the fresh disk
NODE_WAIT = 300  # k3s node Ready after cloud-init is done

UNREACHABLE = 255  # ssh's own exit code for "could not connect"
SSH_OPTIONS = [
    "IdentitiesOnly=yes",
    "BatchMode=yes",
    "ConnectTimeout=10",
    "ServerAliveInterval=5",
    "ServerAliveCountMax=3",
    # The host key changes on every rebuild by design.
    "StrictHostKeyChecking=no",
    "UserKnownHostsFile=/dev/null",
    "LogLevel=ERROR",
]


def log(msg):
    print(f"[rebuild] {msg}", flush=True)


def die(msg):
    log(f"FAILED: {msg}")
    sys.exit(1)


def env(name):
    try:
        return os.environ[name]
    except KeyError:
        die(f"{name} is not set")


def api(method, path, body=None):
    req = urllib.request.Request(
        API + path,
        method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {env('HCLOUD_TOKEN')}",
            "Content-Type": "application/json",
            "User-Agent": "cosmos-rebuild",
        },
    )
    # Reads are retried through network blips, rate limits and 5xx (a rebuild
    # is polled for minutes); writes are sent exactly once.
    attempts = 5 if method == "GET" else 1
    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return json.load(resp)
        except urllib.error.HTTPError as err:
            problem = f"HTTP {err.code}: {err.read().decode(errors='replace')[:500]}"
            retryable = err.code == 429 or err.code >= 500
        except (OSError, http.client.HTTPException) as err:
            problem, retryable = f"unreachable: {err}", True
        if not retryable or attempt == attempts:
            die(f"Hetzner API {method} {path} -> {problem}")
        time.sleep(5 * attempt)


def wait_for(what, timeout, probe, interval=10):
    """Polls probe() until it returns something truthy; None on timeout."""
    deadline = time.monotonic() + timeout
    while True:
        result = probe()
        if result:
            return result
        if time.monotonic() >= deadline:
            return None
        log(f"waiting for {what}...")
        time.sleep(interval)


def wait_action(resp, what):
    action_id = resp["action"]["id"]
    log(f"{what}: action {action_id} started")

    def finished():
        action = api("GET", f"/actions/{action_id}")["action"]
        if action["status"] == "error":
            die(f"{what} failed: {json.dumps(action.get('error'))}")
        return action["status"] == "success"

    if not wait_for(what, ACTION_WAIT, finished, interval=5):
        die(f"{what}: action {action_id} did not finish in {ACTION_WAIT}s")


class Ssh:
    def __init__(self, host, key_path):
        self.host = host
        self.key_path = key_path

    def run(self, script, timeout=60, merge_stderr=True):
        """Returns (exit code, output); UNREACHABLE means ssh itself failed."""
        try:
            proc = subprocess.run(
                [
                    "ssh",
                    f"-i{self.key_path}",
                    *(f"-o{option}" for option in SSH_OPTIONS),
                    f"root@{self.host}",
                    "bash -s",
                ],
                input=script,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT if merge_stderr else subprocess.DEVNULL,
                text=True,
                timeout=timeout,
                check=False,
            )
        except subprocess.TimeoutExpired:
            return UNREACHABLE, "ssh timed out"
        return proc.returncode, proc.stdout.strip()

    def booted_from(self):
        """sha256 of the cloud-init the server booted from; "unknown" if the
        server answers but has none; None if it does not answer."""
        code, out = self.run(f"sha256sum {USER_DATA_PATH}", merge_stderr=False)
        if code == UNREACHABLE:
            return None
        sha = out.split()[0] if code == 0 and out else ""
        return sha if len(sha) == 64 else "unknown"


def runs_image(server, image):
    current = server.get("image") or {}  # null once the image is deleted
    return image in (current.get("name"), str(current.get("id")))


def cloud_init_finished(ssh):
    """True once cloud-init is done and clean; dies on any reported error.

    Reads the JSON form: plain `cloud-init status` says "done" even when a
    stage logged errors (it only shows in the exit code and extended status).
    """
    _, out = ssh.run("cloud-init status --format json", merge_stderr=False)
    try:
        report = json.loads(out)
    except ValueError:
        return False  # not reachable yet, or cloud-init not installed yet
    status = report.get("status")
    errors = list(report.get("errors") or [])
    recoverable = report.get("recoverable_errors") or {}
    errors += recoverable.get("ERROR") or []

    # "not started" is a normal early-boot state and just keeps the wait going.
    if status in ("error", "disabled") or errors:
        detail = "\n".join(f"  {str(e)[:160]}" for e in errors) or "  (no detail)"
        die(
            f"cloud-init status is {report.get('extended_status') or status}:\n"
            f"{detail}\n  full report: cloud-init status --long (on the server)"
        )
    if status not in ("done", "degraded done"):
        return False
    for level, messages in recoverable.items():
        log(f"cloud-init logged {len(messages)} {level} message(s)")
    return True


def verify(ssh, want=None):
    """Blocks until cloud-init finished cleanly and the k3s node is Ready.

    With `want`, also proves the server booted from that cloud-init.
    """
    if not wait_for(
        "cloud-init to finish", CLOUD_INIT_WAIT, lambda: cloud_init_finished(ssh)
    ):
        die(f"cloud-init did not finish in {CLOUD_INIT_WAIT}s")

    if want and not wait_for(
        "the booted cloud-init hash", 60, lambda: ssh.booted_from() == want
    ):
        die(f"server booted from cloud-init {ssh.booted_from()}, expected {want}")

    def node_ready():
        code, _ = ssh.run(
            "k3s kubectl wait --for=condition=Ready node --all --timeout=20s",
            timeout=60,
        )
        return code == 0

    if not wait_for("the k3s node to become Ready", NODE_WAIT, node_ready):
        die(f"k3s node not Ready {NODE_WAIT}s after cloud-init finished")
    log("cloud-init done, k3s node Ready")


def run(ssh, server_id, image, force, user_data):
    want = hashlib.sha256(user_data.encode()).hexdigest()
    log(f"server {server_id}, image {image}, cloud-init {want[:12]}, force={force}")

    # Everything that can be checked goes before any waiting or stopping: past
    # the graceful stop a failure leaves prod down until the next run.
    if not user_data.startswith("#cloud-config"):
        die("stdin is not a cloud-init document")
    if len(user_data.encode()) > USER_DATA_LIMIT:
        die(f"cloud-init is over Hetzner's {USER_DATA_LIMIT} byte user data limit")
    server = api("GET", f"/servers/{server_id}")["server"]
    if server["protection"]["rebuild"]:
        die("the server has rebuild protection enabled")

    have = wait_for("ssh", SSH_WAIT_FORCED if force else SSH_WAIT, ssh.booted_from)
    if have == want and runs_image(server, image) and not force:
        log("server already booted from this cloud-init and image, not rebuilding")
        verify(ssh)
        return

    if have is None:
        if not force:
            die(
                "server is unreachable over ssh, so its services cannot be"
                " stopped cleanly; run ./force-rebuild.sh to rebuild anyway"
            )
        log("server unreachable over ssh, rebuilding without a graceful stop")
    else:
        log(f"server runs cloud-init {have[:12]}, stopping services")
        code, out = ssh.run(GRACEFUL_STOP, timeout=300)
        for line in out.splitlines():
            log(f"  {line}")
        if code != 0 and not force:
            die(
                f"graceful stop failed (exit {code}); nothing was rebuilt, but"
                " services may be down -- re-run the deploy to retry, or"
                " ./force-rebuild.sh to rebuild regardless"
            )
        if code != 0:
            log(f"graceful stop failed (exit {code}), forced: rebuilding anyway")

    started = time.monotonic()
    wait_action(
        api(
            "POST",
            f"/servers/{server_id}/actions/rebuild",
            {"image": image, "user_data": user_data},
        ),
        "rebuild",
    )
    if api("GET", f"/servers/{server_id}")["server"]["status"] == "off":
        log("server is off after the rebuild")
        wait_action(api("POST", f"/servers/{server_id}/actions/poweron"), "poweron")
    verify(ssh, want)
    log(f"rebuilt in {time.monotonic() - started:.0f}s")


def main():
    # delete=True removes the key again; the file is created 0600.
    with tempfile.NamedTemporaryFile("w", prefix="cosmos-key-") as key:
        key.write(env("ARIES").strip() + "\n")
        key.flush()
        run(
            Ssh(env("COSMOS_SERVER_IP"), key.name),
            server_id=env("COSMOS_SERVER_ID"),
            image=env("COSMOS_IMAGE"),
            force=os.environ.get("COSMOS_FORCE_REBUILD") == "1",
            user_data=sys.stdin.read(),
        )


if __name__ == "__main__":
    main()
