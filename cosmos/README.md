# Cosmos

This project provisions a robust, single-node Kubernetes cluster on Hetzner Cloud, designed for durability, security, and GitOps-driven automation. It uses Pulumi (Python) for infrastructure and Argo CD for application delivery.

## 1. Project Identity
*   **Infrastructure Stack:** Pulumi (Python), Hetzner Cloud (hcloud), K3s (Lightweight Kubernetes).
*   **GitOps Engine:** Argo CD (App of Apps pattern).

## 2. Infrastructure Architecture

### Compute & Storage
- **Server:** Ubuntu 24.04 (Type: `cx33`, Location: `fsn1`).
    - **Note:** The server is treated as **ephemeral**. It can be destroyed and replaced at any time ("Nuclear Rebuild") without data loss.
- **Storage:** 50GB Block Storage Volume (`data-volume`).
    - **Persistence:** This volume survives server destruction.
    - **Mounting:** Mounted to `/data` via a robust `runcmd` loop in `cloud-init`, bypassing standard automount to ensuring availability before K3s starts.
    - **Usage:**
        - `/data/k3s-storage`: Backing store for the K3s `local-path` provisioner.
        - `/data/traefik`: Persistent storage for ACME certificates (Host path).
        - `/data/prometheus`, `/data/grafana`, & `/data/alertmanager`: Persistent metrics and dashboards.

### Networking
- **Public IP:** A Static Primary IP is attached to the server.
- **Floating IP:** A separate Floating IP (`49.12.115.123`) is assigned to the server and persisted via a custom **Netplan** configuration in `cloud-init`. This ensures the server is reachable at a consistent address even after a total rebuild.
- **Ingress Controller:** Traefik (v3) bundled with K3s.
    - **Configuration:** Custom `HelmChartConfig` injected via `cloud-init`.
    - **SSL/TLS:** Handled natively by Traefik using Let's Encrypt (Production).
    - **Redirection:** Global HTTP -> HTTPS enforcement enabled via Helm values.
- **Firewall:** Hetzner Cloud Firewall protects the node, allowing only HTTP/HTTPS/SSH. Internal metrics ports (9100/9101) are blocked from public access.

## 3. Secret Management (Total Reproducibility)

This project achieves **Zero-Touch Bootstrap** where passwords and secrets survive total cluster destruction.

### The "Bootstrapped Sealed Secrets" Strategy
1.  **Master Key:** A single RSA key pair is generated locally and stored in the `keys/` directory.
2.  **Encryption:** During `pulumi up`, `__main__.py` reads these keys and injects them into `cloud-init.yaml` as **Pulumi Secrets** (encrypted at rest in the state).
3.  **Pre-seeding:** `cloud-init` writes the key to a Kubernetes Secret (`sealed-secrets-key`) in the `kube-system` namespace *before* K3s fully starts.
4.  **Adoption:** The **Bitnami Sealed Secrets Controller** starts up, detects the existing key, and adopts it.
5.  **Usage:** Application secrets are encrypted locally using `kubeseal` and committed to Git. The controller decrypts them automatically on deploy.

**Result:** Total cluster recovery with identical credentials in minutes.

## 4. GitOps Configuration (Argo CD)

- **Pattern:** **App of Apps**.
- **Bootstrap:** `cloud-init` installs Argo CD and applies the `root-app` manifest.
- **Structure:**
    - **`cosmos/base/`**: Generic Kustomize bases.
    - **`cosmos/overlays/prod/`**: Production-specific patches.
    - **`cosmos/argocd/apps/`**: Argo Application definitions.
- **Image Lifecycle:** **Argo CD Image Updater** monitors GHCR for new tags (`numeric` strategy) and writes changes back to the Git repository via a GitHub PAT.

## 5. Prerequisites

Ensure the following environment variables are set:

- `HCLOUD_TOKEN`: Hetzner Cloud API token.
- `ARIES_PUB`: Public SSH key for the server.
- `ARIES`: Private SSH key (used by Pulumi for remote commands).
- `GH_PAT`: GitHub Personal Access Token (with repo scope).
- `PULUMI_CONFIG_PASSPHRASE`: Local Pulumi encryption passphrase.

## 6. Usage

1. **Install Dependencies:**
   ```bash
   uv sync
   ```

2. **Deploy:**
   ```bash
   pulumi up
   ```

3. **Access:**
   SSH into the server using your `ARIES` key.
   ```bash
   ssh root@49.12.115.123
   ```
   *Note: `KUBECONFIG` is set globally in `/etc/environment`.*

## 7. Key Design Decisions

### SSL/TLS Persistence (The Mapping)
Traefik's ACME storage requires strict permissions (`0600`) and persistence across pod restarts.
*   **Host Path:** `/data/traefik/acme.json` (Managed by `cloud-init` with `chown 65532`).
*   **Static PV:** `traefik-acme-pv` maps the host path `/data/traefik` to the cluster.
*   **Container Mount:** The Traefik pod mounts the PVC at `/data`.
*   **Result:** Within the Traefik container, the file is accessed at **`/data/acme.json`**. This path is configured in the `certificatesResolvers.letsencrypt.acme.storage` section of the Helm values.

### Monitoring Persistence
Prometheus, Grafana, and Alertmanager use a **Static HostPath Binding** strategy. The Operator is configured to bind to specific pre-created PVs (e.g., `prometheus-data-pv`) using Label Selectors, ensuring metrics data persists on `/data/prometheus` between rebuilds.

### Port 9100 Conflict
To avoid conflicts with Node Exporter (host port 9100), Traefik metrics are exposed on **port 9101**.

### Graceful Shutdown
Pulumi manages the lifecycle via `command.remote`: it triggers `systemctl stop k3s` and `umount /data` before the server is destroyed, ensuring the filesystem on the persistent volume remains clean.

## TODOs

- [ ] I should try to minimize downtime
