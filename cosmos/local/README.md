# Cosmos Local

The `dev` stack of [cosmos](../README.md): the **same Pulumi program and the
same cloud-init** (rendered with `env=local` from `../cloud-init.yaml.j2`)
boot a k3s + ArgoCD cluster inside a libvirt/KVM VM instead of a Hetzner
server. This directory holds only the host-side helpers (certs, DNS, git
server, registry, drills) — `pulumi` always runs from `../` with `-s dev`.

| | `prod` stack (Hetzner) | `dev` stack (libvirt) |
|---|---|---|
| Machine | cx33 | KVM VM, 4 vCPU / 8 GB |
| Persistent volume | 50 GB block volume | 20 GB qcow2, `protect=True` |
| Data device | `/dev/disk/by-id/scsi-0HC_Volume_*` | `/dev/vdb` |
| GitOps source | GitHub `HEAD` | host git server, `dev` jj bookmark |
| App overlays | `overlays/prod/*` | `overlays/local/*` (prod + `.test` hosts) |
| TLS | Let's Encrypt (ACME) | mkcert wildcard as Traefik default cert¹ |
| Sealed secrets key | pre-seeded from `../keys/` | same key — all SealedSecrets decrypt |
| Backups | Hetzner Object Storage, `cosmos-prod-backups` | posix repo on a 3rd protected disk (drill prop) |
| Image updater | enabled | disabled (git server is read-only) |
| Reachability | public IP + floating IP | NAT, `192.168.100.10` from this host² |

¹ The `letsencrypt` resolver still exists (pointed at LE **staging**) but can
never complete its challenge locally, so Traefik serves the mkcert default
certificate. Expect harmless ACME errors in the Traefik log.

² **TODO:** bridged network instead of NAT, so LAN devices (phone) can reach
the cluster. Not needed yet; requires bridging the host NIC.

## One-time setup

```bash
# 1. Virtualization (user must be in the libvirt group; re-login after)
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt "$USER"

# 2. Locally-trusted TLS
sudo pacman -S mkcert nss
./bootstrap-certs.sh

# 3. DNS for *.msmetko.test / *.terra-incognita.test -> VM
#    (dnsmasq here is NetworkManager's plugin instance, not dnsmasq.service)
sudo cp dnsmasq-cosmos-local.conf /etc/NetworkManager/dnsmasq.d/
sudo systemctl restart NetworkManager

# 4. Python deps + the dev stack (from cosmos/, shared with prod;
#    no config needed -- dev has no secrets)
cd .. && uv sync
uv run pulumi stack init dev

# 5. direnv env in cosmos/ (gitignored): secrets + local/bin, which holds
#    an mkisofs shim (xorriso-backed) needed by the libvirt provider
printf 'PATH_add local/bin\n' >> .envrc && direnv allow
```

## Bring it up

```bash
./host-services.sh        # git server :8930 + docker registry :5000
./deploy.sh               # point the `dev` bookmark at your working copy
cd .. && uv run pulumi -s dev up   # network, disks, VM (~5 min to green Argo)
```

Then: https://argo.msmetko.test, https://grafana.msmetko.test,
https://jaja.msmetko.test, … SSH with `ssh root@192.168.100.10`
(uses the ARIES key), `k9s` is preinstalled in the VM.

## Daily loop

Edit manifests → `./deploy.sh` → ArgoCD syncs within ~60s. Nothing is ever
pushed to GitHub: the git server only implements `upload-pack` (fetch), and
`dev` is a purely local bookmark.

To test a locally built image: `docker build -t 192.168.100.1:5000/<app>:dev
&& docker push 192.168.100.1:5000/<app>:dev`, then point the app's
`overlays/local` kustomization at that image ref and `./deploy.sh`.

## Nuclear rebuild

```bash
cd .. && uv run pulumi -s dev destroy --exclude-protected && uv run pulumi -s dev up
```

The data volume is protected, so Grafana dashboards, Prometheus data, and the
sealed-secrets state all survive — same rebuild guarantee as prod. To truly
start from scratch: `uv run pulumi -s dev state unprotect --all && uv run pulumi -s dev destroy`.
