# Standalone Postgres: kine datastore, app storage, real backups

*Started 2026-08-02. Companion to `../RUNBOOK.md` (procedures) — this is the
why. Pattern-sibling of `../local/writeup.md`.*

## The itch

Three separate wants converged on the same answer:

1. **k3s state was disposable by design** — embedded SQLite on the ephemeral
   root disk, "rebuild from git" as the recovery story. Elegant, but it means
   every rebuild is a *new* cluster (new CA, re-issued certs, re-synced apps),
   and anything not captured in git (Grafana annotations, in-cluster state)
   dies with the server.
2. **jaja is fully dressed for a database that doesn't exist** — role,
   password, pool size configured; no DB anywhere.
3. **Authelia** (and future apps) need durable storage too, and running a
   Postgres *inside* a single-node k3s that itself needs a datastore is a
   circular dependency waiting to be laughed at.

So: one host-level PostgreSQL, outside k3s, on the survives-everything volume.
k3s becomes just another client (via kine), apps get one database each.

## Decisions, and why

- **One cluster, many databases** — not two instances. Isolation between apps
  is database-level (a PG connection lives in exactly one DB; pg_hba pins each
  role to its own DB and to the pod network). The blast radius argument for a
  dedicated k3s instance is real but not worth 2× the upgrade/backup surface
  on a single 8GB box serving one person.
- **kine, not etcd** — kine is embedded in k3s; `--datastore-endpoint=postgres://`
  turns every k8s object into a row. No etcd anywhere, nothing extra to run.
- **The cluster now *resumes* instead of rebuilding.** Bootstrap data (CA,
  service-account keys) lives in the datastore, encrypted with the k3s token.
  Pin the token → a rebuilt server is the *same* cluster. Recovery ladder:
  (1) resume from `/data`, (2) ArgoCD from git, (3) pgBackRest from S3.
  Subtle trap found while planning: k3s also stores a per-node password in the
  datastore; a rebuilt node presenting a random one is rejected. Hence the
  deterministic `/etc/rancher/node/password` and `--node-name=cosmos`.
- **One master seed, everything derived** (`derive.py`). HMAC-SHA256(seed,
  label) for PG passwords, the k3s token, the pgBackRest cipher pass.
  Deterministic → nothing stored per-credential; one-way → a leaked password
  compromises nothing else; full 256-bit output → no truncation-related
  hand-wringing. Stored secrets are exactly three: seed + two Hetzner S3 keys.
  Future apps: append to `PG_APPS`, done.
- **pgBackRest → Hetzner Object Storage**, WAL archiving + weekly full + daily
  diff, `archive_timeout=300` bounding data loss to ~5 min. Client-side
  AES-256 cipher because **k8s Secrets — including the sealed-secrets master
  key — live in this database**; the ciphertext leaves the machine.
  The bucket is deliberately *not* a Pulumi resource: the backup repo must not
  be in `pulumi destroy`'s blast radius.
- **Config owned in git, not `pg_createcluster`** — the Debian tool refuses
  non-empty data dirs, which is exactly the rebuild-with-existing-data path.
  `create_main_cluster = false` is pre-seeded so the package can't initdb on
  the root disk.
- **`listen_addresses='*'`** — cni0 (10.42.0.1) doesn't exist when PG starts;
  binding the wildcard sidesteps the race. Real exposure control: Hetzner
  firewall (5432 closed) + default-reject pg_hba + (prod) a raw-table iptables
  rule keeping pods away from the metadata service, since user_data now
  carries real secrets.
- **initdb with the builtin locale provider** — an Ubuntu major upgrade
  changing glibc collations can silently corrupt text indexes; the builtin
  provider is immune.
- **PG major pinned in the package name** (`postgresql-18`), tripwire in
  pg-bootstrap comparing `PG_VERSION` against it: a rebuild in 2028 fails loud
  *before* k3s starts, instead of quietly installing PG 21 over an 18 datadir.
  Major upgrades are dump/restore, matching the nuke-everything habit
  (RUNBOOK).
- **Dev's repo is a posix disk, not S3** — dev data is worthless, so it gets
  no real backups; but the restore drills rehearse *restore*, and that needs
  a repo to restore from. A third protected qcow2 (`/backups`) is that prop:
  same pgBackRest, same stanza and cipher machinery, drills stay one-command
  and offline, and dev needs zero Hetzner credentials. The only thing dev
  doesn't rehearse is the S3 transport itself — staging covers that.

## Testing ladder

Dev stack (drills in RUNBOOK) → ephemeral Hetzner staging stack
(`*.staging.msmetko.xyz`, proves hcloud volume behavior + real ACME)
→ prod cutover by ordinary merge. First cutover is the last true "nuclear
rebuild": `/data/postgres` is empty, so the cluster is rebuilt from git one
final time — and every rebuild after that is a resume.

Rollback at any point: revert the change, CI rebuilds on SQLite exactly as
before; `/data/postgres` and the bucket sit dormant.

## Open ends

- Alertmanager has no receivers — alerts render in the UI but notify no one.
- jaja still needs `DATABASE_HOST=10.42.0.1` wired (and its local overlay
  reuses the *prod* sealed secret, so its local DB password won't match until
  it gets its own — same deliberate deviation Authelia's local overlay makes).
- forwardAuth middleware exists but protects nothing yet.
- Backups are same-provider, same-region as prod. A second pgBackRest repo
  (different provider) would make it true 3-2-1.
