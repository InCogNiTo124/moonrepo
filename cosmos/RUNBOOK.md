# Cosmos runbook

Procedures only; the reasoning lives in `writeups/postgres.md` and `README.md`.

## One-time bootstrap

1. **Bucket** (Hetzner console, deliberately outside Pulumi so no stack
   operation can ever touch the backups): create the `cosmos-prod-backups`
   Object Storage bucket in `fsn1` (a staging one comes later) plus an S3
   credential pair. The dev stack needs neither — its pgBackRest repo is a
   local posix disk.
2. **Prod secrets** (from `cosmos/`, with `PULUMI_CONFIG_PASSPHRASE` set):
   ```bash
   uv run pulumi -s prod config set --secret cosmos_master_seed "$(openssl rand -hex 32)"
   uv run pulumi -s prod config set --secret s3_access_key <key>
   uv run pulumi -s prod config set --secret s3_secret_key <secret>
   ```
   Commit the updated `Pulumi.prod.yaml`. (`s3_bucket` is already committed.)
3. **Password manager**: store the master seed, the Pulumi passphrase, and the
   S3 credentials. Losing the seed = the k3s datastore bootstrap and the
   pgBackRest repo become permanently undecryptable.

## Derived credentials

Everything except the S3 keys is derived from the seed (`cosmos/derive.py`):

```bash
uv run pulumi -s prod config get cosmos_master_seed | uv run python derive.py pg-jaja
```

Labels: `k3s-token`, `pgbackrest-cipher`, `pg-kine`, `pg-<app>` for every app
in `PG_APPS`. The dev stack uses the fixed seed `cosmos-local-seed`.

## Adding an app database

1. Append the name to `PG_APPS` in `cosmos/derive.py` — the next deploy
   creates the role + database and opens pg_hba for it (pod network only).
2. Derive its password (label `pg-<name>`) and seal it into the app's
   SealedSecret. In-cluster DB address is always `10.42.0.1:5432`.

## Rebuild semantics ("nuclear rebuild" = resume)

`pulumi up` after any change to the server replaces it (`delete_before_replace`):
old server stops k3s → backup timers → Postgres, unmounts `/data`; new server
remounts `/data`, reinstalls PG (same pinned major, latest minor), finds the
existing data dir, and k3s re-adopts the existing datastore via the derived
token — the *same* cluster resumes: same CA, same Secrets, same PVs.

- Never skip more than one Kubernetes minor between rebuilds.
- After an Ubuntu major bump nothing special is needed (initdb used the
  builtin locale provider, so glibc collation changes can't corrupt indexes).

## Restore

All commands as root on the server. `pg-restore.sh` refuses to run without
`--yes-destroy-data`.

**In-place (bad data / corruption), latest backup:**
```bash
/opt/cosmos/pg-restore.sh --yes-destroy-data
```

**Point-in-time:**
```bash
/opt/cosmos/pg-restore.sh --yes-destroy-data --type=time "--target=2026-08-02 10:00:00+00" --target-action=promote
```

**Full loss (server AND volume gone):**
1. `uv run pulumi up` — fresh volume, fresh (empty) PG, cluster boots new.
2. `/opt/cosmos/pg-restore.sh --yes-destroy-data` — pulls the repo state back
   (prod: object storage; dev: the backup disk); k3s restarts against the
   restored datastore.
3. Verify (below). ArgoCD self-heal converges anything newer than the backup.

**Verify after any restore:** node `Ready`; all Applications Synced/Healthy;
sealed secrets decrypting (`kubectl get sealedsecrets -A`); `sudo -u postgres
pgbackrest --stanza=cosmos info` shows the expected backups; a WAL archive is
advancing (`select * from pg_stat_archiver`).

## PostgreSQL major upgrade

DBs are megabytes — dump/restore beats `pg_upgrade` surgery here:

1. On the old server: `sudo -u postgres pg_dumpall > /data/pg_dumpall.sql`
2. Bump the major once in `cloud-init.yaml.j2` (`{% set pg_major = NN %}`).
3. Deploy. The bootstrap tripwire sees the old-major data dir and **halts
   cloud-init** — this is expected: SSH in, `mv /data/postgres/<old> /data/postgres/<old>.pre-upgrade`,
   re-run `cloud-init` modules or reboot (fresh initdb on the new major runs).
4. `sudo -u postgres psql -f /data/pg_dumpall.sql postgres`, then re-run
   `/opt/cosmos/pg-bootstrap.sh` (re-syncs passwords).
5. `sudo -u postgres pgbackrest --stanza=cosmos stanza-upgrade`, then a fresh
   full backup: `systemctl start pgbackrest-full.service`.

## Drills (do these, they're the whole point)

| Drill | Where | Cadence |
|---|---|---|
| Rebuild-resume (`pulumi destroy` VM, keep data disk → `up`) | local twin | after any cloud-init change |
| In-place restore | local twin | monthly-ish |
| Full-loss restore (VM + data disk wiped) | local twin | quarterly-ish |
| Rebuild-resume (replace server, keep volume) | staging/prod | before + after first cutover |

## Rotation

Rotate the seed = new seed in config + rebuild (bootstrap `ALTER ROLE`s new
passwords, k3s token changes → datastore bootstrap re-keys) + re-seal every
app SealedSecret that embeds a derived password + `stanza-create` against a
fresh repo path (old backups stay readable with the old cipher pass only).
Rotate S3 keys freely — config change + rebuild, nothing else depends on them.
