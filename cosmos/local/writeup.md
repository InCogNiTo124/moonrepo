# Cosmos Local: Production-at-Home — The Full Writeup

*2026-07-07. The story of building a local twin of the Hetzner production cluster:
the idea, the design, everything that broke, and what it taught us.*

---

## 1. The Idea

**Goal:** a "production-at-home" environment that emulates the Hetzner `cosmos`
setup faithfully enough to iterate on Grafana dashboards, test every project
(brachi, jaja, kepler-orbit, personal-blog, personal-website), and rehearse
infrastructure changes — without touching prod and without pushing anything to
GitHub.

**What prod is:** Pulumi (Python) provisions a single Hetzner cx33 whose
cloud-init does everything: mounts a persistent 50 GB block volume at `/data`,
pre-seeds the Bitnami sealed-secrets master key, configures Traefik (ACME/Let's
Encrypt, metrics, plugins) via k3s `HelmChartConfig` manifests, installs k3s,
and bootstraps an ArgoCD app-of-apps (`root-app`) that deploys everything else
from this repo. The server is ephemeral by design ("nuclear rebuild"); the
volume is the only state.

**Requirements pinned down up front (Q&A):**

- Highest fidelity: a **VM consuming the actual cloud-init**, not k3d/kind.
- Test **uncommitted-to-GitHub work**: ArgoCD reads the local working repo;
  nothing is ever pushed to origin.
- **jj (jujutsu)** is the VCS driver — non-negotiable. Colocated repo.
- Images ideally from the local machine; a simple registry is fine.
- Secrets: low ceremony; reusing the prod sealed-secrets master key is fine
  (it already lives on this machine in the gitignored `cosmos/keys/`).
- Domains: local TLD variants (settled on `.test`, see §5.1), dnsmasq for DNS.
- Certs: any solution that works; landed on mkcert (one approved install).
- Persistent "block volume" emulation: yes — rebuilds must preserve dashboards.
- No global installs; every Python thing in a per-directory uv project;
  pulumi always invoked as `uv run pulumi`.

**The three-rung ladder** (the local twin is rung 1; rung 2 exists as a design):

| | local (libvirt) | staging (Hetzner, ephemeral) | prod (Hetzner) |
|---|---|---|---|
| Machine | KVM VM 4 vCPU/8 GB | cx22, hours, ~cents | cx33 |
| Tracks | `dev` jj bookmark via local git server | `staging` branch on GitHub | `main` |
| Certs | mkcert wildcard | LE staging CA | LE production |
| Proves | logic, manifests, dashboards | Hetzner boot path, real ACME, sizing | — |

Staging is just `Pulumi.staging.yaml` + a DNS wildcard away — same
`__main__.py`, same template, different values. Not built yet.

---

## 2. The Solution / Architecture

```
   HOST (Manjaro, 20 cores / 62 GB)                    VM  192.168.100.10
  ┌─────────────────────────────────┐   libvirt NAT   ┌──────────────────────┐
  │ moonrepo (jj colocated .git)    │  virbr1 (.1)    │ Ubuntu 24.04 (noble) │
  │   └── `dev` bookmark ──────────────┐              │  cloud-init (shared  │
  │ git_server.py        :8930  ◄──────┼── ArgoCD     │   template, env=local│
  │ registry:2           :5000  ◄──────┼── containerd │  k3s + Traefik       │
  │ NM dnsmasq: *.test → .10    │      │              │  ArgoCD app-of-apps  │
  │ mkcert CA (system trust)    │      │              │  sealed-secrets      │
  │ pulumi (cosmos/local, uv)   │      │              │  kube-prom-stack     │
  └─────────────────────────────┘      │              │  /dev/vdb → /data ───┼─► persistent
                                       │              └──────────────────────┘   qcow2
        browser ── https://jaja.msmetko.test ──► Traefik (mkcert default cert)
```

**The single most important design property:** prod and local boot from the
*same* cloud-init template (`cosmos/cloud-init.yaml.j2`, Jinja2, `env=prod|local`).
Divergences are explicit `{% if env == ... %}` blocks, greppable and reviewable:

| Concern | prod | local |
|---|---|---|
| Data device | `/dev/disk/by-id/scsi-0HC_Volume_<id>` | `/dev/vdb` |
| Floating-IP netplan | present | omitted |
| ACME CA | LE production | LE staging (can never succeed → Traefik serves the default cert; harmless log noise) |
| Default TLS | — | mkcert wildcard as Traefik `TLSStore` default + Secret |
| Repo | GitHub + PAT secret | `http://192.168.100.1:8930/moonrepo`, `insecure: "true"` |
| root-app | `cosmos/argocd/apps` @ `HEAD` | `cosmos/argocd/apps/overlays/local` @ `dev` |
| Registry | — | `registries.yaml` trusting `192.168.100.1:5000` (plain HTTP) |
| Root SSH | injected by Hetzner | ARIES_PUB written to `/root/.ssh/authorized_keys` |

**The GitOps loop with jj.** The repo is colocated (`.jj` + `.git`), so jj
already maintains real git objects. ArgoCD needs a *ref*; jj's working-copy
commit `@` is anonymous. The bridge is a bookmark: `deploy.sh` runs
`jj bookmark set dev -r @ --allow-backwards`, which (a) auto-snapshots the
working copy — jj does this on every command — and (b) auto-exports `dev` as a
git branch in the colocated `.git`. ArgoCD polls every 60 s
(`timeout.reconciliation` was already 60 s in prod). Deploying the working
copy is literally one command; "uncommitted work" isn't a concept that exists.

**Read-only by construction.** `git_server.py` (~80 lines, stdlib only) speaks
git smart-HTTP but implements *only* `git-upload-pack` (fetch/clone). There is
no code path for `receive-pack`; a push gets a 403. Verified with a real clone
and a real rejected push. The `dev` bookmark is never `jj git push`ed.

**ArgoCD structure (unified base + overlays, no parallel trees):**

```
cosmos/argocd/
├── apps/
│   ├── kustomization.yaml        # → overlays/prod  (see §5.0 — this line
│   ├── base/                     #    prevents prod from pruning itself)
│   │   ├── kustomization.yaml    # all 12 Application/manifest files
│   │   └── *.yaml
│   └── overlays/
│       ├── prod/                 # passthrough: resources: ../../base
│       └── local/                # patches: repoURL/dev/paths, deletes
│                                 #   image-updater, .test hosts for argo+grafana
├── base/<app>/                   # untouched
└── overlays/
    ├── prod/<app>/               # untouched
    └── local/<app>/              # resources: ../../prod/<app> + one JSON
                                  #   patch: Ingress host → .test
```

Local overlays *stack on top of prod overlays*, so a prod change flows into
local for free. The image updater is deleted locally (it writes commits back
via the GitHub PAT — impossible and unwanted against a read-only server); its
annotations remain on the apps but are inert without the controller.

**Sealed secrets:** the prod master keypair from `cosmos/keys/` is pre-seeded
into the local cluster the same way cloud-init does it in prod. Every
committed SealedSecret decrypts unchanged — same Grafana/ArgoCD credentials as
prod, zero re-sealing, and the full mechanism is exercised.

**Persistence:** a 20 GB qcow2 attached as `/dev/vdb`, `protect=True` in
Pulumi. `uv run pulumi destroy --exclude-protected && uv run pulumi up` is the
nuclear rebuild: fresh VM, same data. Prometheus data, Grafana dashboards,
and the ext4 filesystem itself survive — mirroring the Hetzner volume story.

---

## 3. The Parts

**Repo changes (two jj changes: a prod-side `refactor(cosmos)` — jinja2
template + argocd base/overlays — and `feat(prod)` with the standalone
postgres plus everything below that is dev-stack-only):**

- `cosmos/cloud-init.yaml.j2` — the shared template (was `cloud-init.yaml`
  with `str.format`). Prod render verified **semantically identical** to the
  old output: unified diff showed only the header comment and
  trailing-whitespace-on-blank-lines; `yaml.safe_load(old) == yaml.safe_load(new)`.
- `cosmos/__main__.py` — renders the template via Jinja2
  (`trim_blocks`, `lstrip_blocks`, `keep_trailing_newline`, `StrictUndefined`),
  passes `env="prod"` and the computed `data_device`.
- `cosmos/pyproject.toml` — + `jinja2`.
- `cosmos/argocd/apps/{base,overlays/{prod,local}}` + top-level
  `apps/kustomization.yaml` — restructure described above; every variant
  build-verified with `kubectl kustomize`.
- `cosmos/argocd/overlays/local/<app>/` × 5 — host patches:
  `jaja.msmetko.test`, `brachi.msmetko.test`, `orbit.msmetko.test`,
  `msmetko.test`, `terra-incognita.test` (+ `argo.`/`grafana.` at apps level;
  grafana via ArgoCD helm `parameters` — `grafana.ingress.hosts[0]` — to avoid
  duplicating the whole inline values block).

**The `dev` stack (same `cosmos/__main__.py`, `pulumi -s dev`; the libvirt
branch of the program) plus host-side helpers in `cosmos/local/`:**

- `__main__.py` (dev branch) — Provider (`qemu:///system`), dir Pool, NAT
  Network (192.168.100.0/24, DHCP host entry pins the VM to `.10` via
  `DomainNetworkInterfaceArgs(addresses=[...], wait_for_lease=True)`),
  Ubuntu noble cloud image Volume (downloaded by the provider), 25 GB root
  disk (CoW on the base image; cloud-init growpart expands), 20 GB protected
  data volume, CloudInitDisk from the shared template, Domain (4 vCPU/8 GB,
  autostart, serial console).
- `git_server.py` — the read-only smart-HTTP server (stdlib; handles the
  gzip-encoded POST bodies git sends).
- `bin/mkisofs` — 3-line xorriso shim (§5.3).
- `bootstrap-certs.sh` — mkcert CA + wildcard cert for
  `*.msmetko.test`/`*.terra-incognita.test` into gitignored `certs/`.
- `host-services.sh` — idempotent: `registry:2` container + git server.
- `deploy.sh` — the one-command deploy.
- `dnsmasq-cosmos-local.conf` — two `address=/…/192.168.100.10` wildcards,
  installed to `/etc/NetworkManager/dnsmasq.d/` (§5.2).
- `../.envrc` (gitignored) — secrets + `PATH_add local/bin`.
- `README.md` — runbook + TODOs.

---

## 4. What Went Right First Try

- The Jinja refactor (render-diff methodology caught drift before it existed).
- The kustomize restructure — all builds green on first `kubectl kustomize`.
- The git server — first clone worked, first push correctly rejected.
- jj bookmark → git export → ArgoCD sync chain worked exactly as theorized.
- Sealed-secrets key reuse: all three SealedSecrets decrypted on first boot.
- The persistence plumbing: `/dev/vdb` was detected, formatted, and mounted by
  the same `runcmd` loop prod uses.
- mkcert: every `.test` host serves a browser-trusted cert
  (`curl` TLS verify result 0, no `-k`).

---

## 5. Wrong Assumptions, Failures, Fixes

### 5.0 The near-miss that never fired: prod pruning itself

Early design had local Applications in a parallel `apps-local/` dir; after
unifying into `apps/base` + overlays, the *first* draft moved all files out of
`apps/`. Caught at design time: the **running** prod root-app points at
`cosmos/argocd/apps` with `automated: {prune: true}`. Merge that layout and
prod's Argo finds an empty directory → **prunes every Application in the
cluster**. The fix is the top-level `apps/kustomization.yaml` (resources:
`overlays/prod`): ArgoCD detects a kustomization and renders it, so the
existing prod root-app keeps producing identical output through the
restructure, zero-downtime, no cloud-init change needed for prod.

**Lesson:** with auto-prune GitOps, a *file move* is a production change. Ask
"what does the currently-deployed pointer see after this merge?" for every
restructure.

### 5.1 `.local` is not a normal TLD

Original plan said `msmetko.local` — but `.local` is reserved for
mDNS/Avahi; resolution via unicast DNS is nonstandard and flaky on desktop
Linux. `.test` is IETF-reserved for exactly this purpose (RFC 2606/6761).
Cheap catch, would have been a confusing intermittent failure.

### 5.2 "Restart dnsmasq" — wrong dnsmasq (first real failure)

**Assumption:** dnsmasq runs as the standalone `dnsmasq.service`, configured
from `/etc/dnsmasq.d/`.

**Reality:** this host runs dnsmasq as a **NetworkManager plugin**
(`dns=dnsmasq` in `NetworkManager.conf`): NM spawns its own instance on
127.0.0.1:53 with `--conf-file=/dev/null --conf-dir=/etc/NetworkManager/dnsmasq.d`.
So the copied conf file was never read by anything, *and*
`systemctl restart dnsmasq` started a second instance that died in a
crash-loop ("failed to create listening socket for port 53: Address already in
use") until systemd's start-limit tripped.

**Fix:** move the file to `/etc/NetworkManager/dnsmasq.d/`,
`systemctl reset-failed dnsmasq` (leave the unit disabled), and
`systemctl restart NetworkManager`. Verified with
`dig +short jaja.msmetko.test @127.0.0.1` → `192.168.100.10`.

**Lesson:** "I use dnsmasq" is ambiguous — standalone daemon vs NM plugin vs
libvirt's per-network instances (there are *three* dnsmasq flavors involved in
this project). Check `pgrep -a dnsmasq` and who owns :53 before writing
instructions. The evidence was even sitting there: existing NM dnsmasq rules
(`address=/php74/…`) from earlier work.

### 5.3 `mkisofs: executable file not found` (first `pulumi up` failure)

**Assumption (implicit):** the libvirt provider's dependencies are pure-Go.

**Reality:** the NoCloud datasource — how *every* non-cloud libvirt VM gets
its cloud-init config — is a tiny ISO9660 image labeled `cidata` attached as a
CD-ROM. The pulumi/terraform libvirt provider builds it by shelling out to a
binary literally named `mkisofs`, with no fallback. Manjaro doesn't package
cdrtools (`mkisofs`) or cdrkit (`genisoimage`) — only libburnia's **xorriso**,
which ships a 1:1 emulation (`xorriso -as mkisofs`, alias binary `xorrisofs`).
The 25-year cdrtools licensing soap opera means every distro ships a different
subset of three names for the same tool, and the provider hardcodes the one
name this system lacks. (Previous qemu+cloud-init experience never hit this
because `virt-install --cloud-init` builds the ISO with pycdlib, a bundled
pure-Python library.)

**Fix:** no new package — a committed 3-line shim `cosmos/local/bin/mkisofs`
(`exec xorriso -as mkisofs "$@"`) plus `PATH_add bin` in the direnv `.envrc`,
so it exists only inside this project directory.

**Process miss:** the `.envrc` line was appended without asking first.
Environment/dotfiles deserve a heads-up *before* the edit, not a README diff
after. Acknowledged; the shim stayed by choice.

**Upstream idea:** the provider could try `mkisofs` → `xorrisofs` →
`genisoimage`. A small PR to terraform-provider-libvirt would fix this for
every Arch-family user; pulumi-libvirt inherits it (bridged provider).

### 5.4 Docker silently killed the VM's internet (the big one)

**Symptom:** cloud-init stuck; `/var/log/cloud-init-output.log` showed the k9s
download on retry #7. From inside the VM: DNS fine (libvirt dnsmasq is local),
**VM→host TCP fine** (`:8930` reachable), **VM→internet 100 % dead** — ICMP
and TCP both. That split is the tell: VM→host is the INPUT chain on the host;
VM→internet traverses **FORWARD**.

**Diagnosis chain:** `ip_forward=1` ✓, no firewalld/ufw ✓, libvirt network XML
correct (`<forward mode='nat'>`) ✓ → therefore FORWARD filtering. Host runs
libvirt **12.5**, which defaults to the **nftables** firewall backend
(`network.conf` had no override); Docker programs the classic **iptables**
FORWARD chain and sets its policy to **DROP** (it has done this since 17.06).
Under nftables these are *independent hook chains* and a packet must be
accepted by **both** — libvirt ACCEPTing in `table ip libvirt_network` does
not exempt the packet from Docker's DROP in `table ip filter`. Every
distro-forum "libvirt NAT broken" thread of the last few years is this bug.

The kicker: Docker was only running because of **our own registry container**.
The twin's image-testing feature broke the twin's internet.

**Fix:** one line — `firewall_backend = "iptables"` in
`/etc/libvirt/network.conf`, `systemctl restart libvirtd`. libvirt then
inserts its ACCEPT rules at the *top of the same FORWARD chain* Docker
polices, short-circuiting the DROP policy. Persistent, standard, no per-boot
rules. (Alternative considered: ACCEPTs in `DOCKER-USER` — works but isn't
reboot-persistent without extra machinery.)

**Recovery surprise:** no rebuild needed. The fix landed *mid-first-boot*
while wget was still in its retry loop; the moment forwarding worked, the
download succeeded and cloud-init marched on — k9s, k3s, ArgoCD, everything.
Crude retry loops in `runcmd` turned out to be accidental self-healing.

**Lesson:** when a VM/container can reach its host but not the internet, it's
a FORWARD-path problem, and the first question on any Docker-carrying host is
"who else is programming netfilter, and in which backend?" Also: the
dependencies you add to *support* a system (registry → dockerd) are part of
the system and can break it.

### 5.5 Trivia that still cost minutes

- **zsh doesn't word-split unquoted variables**: a monitor script doing
  `SSH="ssh -i …"; $SSH true` failed with "no such file or directory: ssh -i …"
  — the whole string was one word. Use a function (`vmssh() { ssh … "$@"; }`)
  or `${=SSH}`. The Bash tool on this host runs zsh; write accordingly.
- The PyPI `pulumi` package is SDK-only — `.venv/bin` has no `pulumi` binary.
  `uv run pulumi` still does the right thing: resolves the system CLI but runs
  it inside the project venv, so the Python language plugin sees the locked
  deps. This is the required invocation for this repo.

---

## 6. Final Verified State (2026-07-07)

- `uv run pulumi up`: 9 resources, VM at 192.168.100.10, ~5.5 min from create
  to green Argo.
- All 8 Applications **Synced/Healthy**: root-app, brachi, jaja, kepler-orbit,
  personal-blog, personal-website-prod, kube-prometheus-stack, sealed-secrets.
- HTTPS 200 with **valid TLS** (system-trusted mkcert chain) on
  jaja/brachi/orbit/msmetko/terra-incognita/argo`.test`; grafana 302→login.
- SealedSecrets: `argocd-secret`, `jaja-secret`, `grafana-admin-credentials`
  all `SYNCED: True`, decrypted Secrets present.
- Monitoring: Prometheus, Grafana, Alertmanager, node-exporter,
  kube-state-metrics all Running; state on `/dev/vdb`.
- `/data` on `/dev/vdb` (ext4, 20 G), created by the shared runcmd loop.

**Daily loop:** edit → `cosmos/local/deploy.sh` → Argo syncs ≤60 s.
**Rebuild:** `uv run pulumi destroy --exclude-protected && uv run pulumi up`.
**Local image test:** `docker build -t 192.168.100.1:5000/<app>:dev . &&
docker push …` → point the app's local overlay at it → `deploy.sh`.

## 7. Open Items

- [ ] **Bridged network** (replace NAT) so LAN devices — the phone — can reach
      the cluster. Not needed soon.
- [ ] **Hetzner staging stack**: `Pulumi.staging.yaml` (cx22, LE staging,
      `staging` branch, `apps/overlays/staging`) + a reserved IP with
      `*.staging.msmetko.xyz`. The Jinja `env` plumbing already supports it.
- [ ] **Upstream** the mkisofs→xorrisofs fallback to terraform-provider-libvirt.
- [ ] Subdomain→path migration (e.g. `orbit.msmetko.xyz` →
      `msmetko.xyz/projects/orbit`): local overlays are wildcard-DNS'd, so
      only the per-app host patches need touching when it happens.
