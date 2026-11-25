"""One Pulumi program, three stacks.

  dev      -- libvirt/KVM twin of prod on this machine (host-side helpers,
              drills and the writeup live in cosmos/local/)
  staging  -- throwaway Hetzner stack for prod-like validation (not built yet)
  prod     -- the real Hetzner server

Every stack renders the same cloud-init.yaml.j2: the dev stack with
env="local" (mkcert TLS, host git server + registry), Hetzner stacks with
env="prod". Hetzner stacks back up to Hetzner Object Storage; the dev stack
keeps a local posix pgBackRest repo on a third disk -- dev data is worthless,
but the restore drills need a repo to restore from.
"""

import hashlib
import os
import pathlib
from enum import Enum

import jinja2
import pulumi
import pulumi_command as command
import pulumi_hcloud as hcloud
import pulumi_libvirt as libvirt

from derive import PG_APPS, derive, pg_passwords
from rebuild import STOP_SERVICES

STACK = pulumi.get_stack()
COSMOS = pathlib.Path(__file__).resolve().parent


class LetsEncryptEnv(Enum):
    STAGING = "https://acme-staging-v02.api.letsencrypt.org/directory"
    PRODUCTION = "https://acme-v02.api.letsencrypt.org/directory"


config = pulumi.Config()


def indent(text, spaces):
    return "\n".join(" " * spaces + line for line in text.splitlines())


def render_cloud_init(**env_specific):
    jenv = jinja2.Environment(
        loader=jinja2.FileSystemLoader(COSMOS),
        trim_blocks=True,
        lstrip_blocks=True,
        keep_trailing_newline=True,
        undefined=jinja2.StrictUndefined,
    )
    return jenv.get_template("cloud-init.yaml.j2").render(
        email="msmetko@msmetko.xyz",
        pg_apps=PG_APPS,
        **env_specific,
    )


def require_env(name):
    """A missing variable must stop the run, not render into cloud-init as an
    empty string (GH_PAT) or surface halfway through a rebuild (ARIES)."""
    try:
        return os.environ[name]
    except KeyError as err:
        raise pulumi.RunError(
            f"{name} is not set. The prod stack needs HCLOUD_TOKEN, ARIES,"
            " ARIES_PUB and GH_PAT (CI secrets; locally cosmos/.envrc)."
        ) from err


def read_key(path):
    try:
        return path.read_text()
    except FileNotFoundError as err:
        raise pulumi.RunError(
            f"{path} is missing. Run cosmos/local/bootstrap-certs.sh first (for"
            " certs/) or make sure the sealed-secrets master key pair exists in"
            " cosmos/keys/."
        ) from err


if STACK == "dev":
    # The NAT network: the host is always the gateway (.1), the VM is pinned
    # to .10
    NETWORK_CIDR = "192.168.100.0/24"
    HOST_IP = "192.168.100.1"
    VM_IP = "192.168.100.10"

    GIT_SERVER = f"http://{HOST_IP}:8930/moonrepo"
    REGISTRY = f"{HOST_IP}:5000"

    # Fixed seed instead of a Pulumi-config secret (low security is fine
    # here, same reasoning as reusing the sealed-secrets master key).
    MASTER_SEED = "cosmos-local-seed"

    GiB = 1024**3

    # No secrets involved (fixed seed, posix backup repo) -> render eagerly
    cloud_init_data = render_cloud_init(
        env="local",
        data_device="/dev/vdb",
        backup_device="/dev/vdc",
        ca_server=LetsEncryptEnv.STAGING.value,
        ss_private_key=indent(read_key(COSMOS / "keys" / "master-private.pem"), 10),
        ss_public_cert=indent(read_key(COSMOS / "keys" / "master-public.pem"), 10),
        repo_url=GIT_SERVER,
        target_revision="dev",
        apps_path="cosmos/argocd/apps/overlays/local",
        registry=REGISTRY,
        tls_cert=indent(read_key(COSMOS / "local" / "certs" / "wildcard.pem"), 10),
        tls_key=indent(read_key(COSMOS / "local" / "certs" / "wildcard-key.pem"), 10),
        ssh_pub_key=os.environ["ARIES_PUB"].strip(),
        k3s_token=derive(MASTER_SEED, "k3s-token"),
        pgbackrest_cipher_pass=derive(MASTER_SEED, "pgbackrest-cipher"),
        pg_passwords=pg_passwords(MASTER_SEED),
    )

    provider = libvirt.Provider("libvirt", uri="qemu:///system")
    opts = pulumi.ResourceOptions(provider=provider)

    pool = libvirt.Pool(
        "cosmos-local",
        type="dir",
        target=libvirt.PoolTargetArgs(path="/var/lib/libvirt/cosmos-local"),
        opts=opts,
    )

    # TODO: bridged network so LAN devices (e.g. a phone) can reach the cluster
    network = libvirt.Network(
        "cosmos-local-net",
        mode="nat",
        autostart=True,
        addresses=[NETWORK_CIDR],
        dhcp=libvirt.NetworkDhcpArgs(enabled=True),
        dns=libvirt.NetworkDnsArgs(enabled=True),
        opts=opts,
    )

    base_image = libvirt.Volume(
        "ubuntu-24.04-base",
        pool=pool.name,
        source="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img",
        format="qcow2",
        opts=opts,
    )

    root_disk = libvirt.Volume(
        "root-disk",
        pool=pool.name,
        base_volume_id=base_image.id,
        size=25 * GiB,
        format="qcow2",
        opts=opts,
    )

    # The stand-in for the Hetzner block volume: survives `pulumi destroy
    # --exclude-protected` so dashboards/metrics/certs persist across rebuilds.
    data_volume = libvirt.Volume(
        "data-volume",
        pool=pool.name,
        size=20 * GiB,
        format="qcow2",
        opts=pulumi.ResourceOptions(provider=provider, protect=True),
    )

    # pgBackRest's posix repo (prod uses Hetzner Object Storage instead). A
    # separate protected disk so the full-loss drill can wipe the data disk
    # and still have a repo to restore from -- it's a drill prop, not a backup.
    backup_volume = libvirt.Volume(
        "backup-disk",
        pool=pool.name,
        size=5 * GiB,
        format="qcow2",
        opts=pulumi.ResourceOptions(provider=provider, protect=True),
    )

    cloudinit_disk = libvirt.CloudInitDisk(
        "cloud-init",
        pool=pool.name,
        user_data=cloud_init_data,
        opts=opts,
    )

    cosmos_local = libvirt.Domain(
        "cosmos-local",
        memory=8192,  # match the cx33 (4 vCPU / 8 GB)
        vcpu=4,
        autostart=True,
        cloudinit=cloudinit_disk.id,
        disks=[
            libvirt.DomainDiskArgs(volume_id=root_disk.id),  # /dev/vda
            libvirt.DomainDiskArgs(volume_id=data_volume.id),  # /dev/vdb
            libvirt.DomainDiskArgs(volume_id=backup_volume.id),  # /dev/vdc
        ],
        network_interfaces=[
            libvirt.DomainNetworkInterfaceArgs(
                network_id=network.id,
                addresses=[VM_IP],
                wait_for_lease=True,
            )
        ],
        consoles=[
            libvirt.DomainConsoleArgs(type="pty", target_port="0", target_type="serial")
        ],
        opts=opts,
    )

    pulumi.export("ip", VM_IP)
    pulumi.export("ssh", f"ssh root@{VM_IP}")
    pulumi.export("kubeconfig", f"ssh root@{VM_IP} cat /etc/rancher/k3s/k3s.yaml")

elif STACK == "prod":
    SERVER_IMAGE = "ubuntu-24.04"

    require_env("HCLOUD_TOKEN")  # read by the hcloud provider and rebuild.py
    GH_PAT = require_env("GH_PAT")
    ARIES = require_env("ARIES")
    ARIES_PUB = require_env("ARIES_PUB")

    # 1. Create Volume (Independent)
    # We disable automount here/in attachment because cloud-init mounts it
    # itself (the runcmd mount loop in cloud-init.yaml.j2)
    volume = hcloud.Volume(
        "data-volume",
        size=50,
        format="ext4",
        location="fsn1",
        opts=pulumi.ResourceOptions(protect=True),
    )

    ss_public_cert = config.get_secret("sealed_secrets_public_cert")
    ss_private_key = config.get_secret("sealed_secrets_private_key")

    # The single secret everything else derives from (see cosmos/derive.py and
    # cosmos/RUNBOOK.md). Losing it means the surviving datastore can never be
    # adopted by a rebuilt server: k3s bootstrap data is encrypted with the
    # derived token, and the pgBackRest repo with the derived cipher pass.
    master_seed = config.require_secret("cosmos_master_seed")

    # Hetzner Object Storage (pgBackRest repo): the bucket is a manual
    # one-time bootstrap (console, see RUNBOOK.md) -- deliberately never a
    # Pulumi resource, so no stack operation can ever touch the backups.
    # Keys are Hetzner-issued and project-scoped.
    s3_access_key = config.require_secret("s3_access_key")
    s3_secret_key = config.require_secret("s3_secret_key")
    s3_bucket = config.require("s3_bucket")
    s3_endpoint = config.get("s3_endpoint") or "fsn1.your-objectstorage.com"
    s3_region = config.get("s3_region") or "fsn1"

    # Create Static IP
    floating_ip = hcloud.FloatingIp.get(resource_name="terra-incognita", id="63752554")

    def create_cloud_init(args, gh_pat):
        # We inject the specific Volume ID for the /dev/disk/by-id path
        return render_cloud_init(
            env="prod",
            data_device=f"/dev/disk/by-id/scsi-0HC_Volume_{args['vol_id']}",
            ca_server=LetsEncryptEnv.PRODUCTION.value,
            gh_pat=gh_pat,
            ss_private_key=indent(args["ss_priv"], 10),
            ss_public_cert=indent(args["ss_pub"], 10),
            floating_ip=args["floating_ip_addr"],
            repo_url="https://github.com/InCogNiTo124/moonrepo",
            target_revision="HEAD",
            apps_path="cosmos/argocd/apps",
            k3s_token=derive(args["seed"], "k3s-token"),
            pgbackrest_cipher_pass=derive(args["seed"], "pgbackrest-cipher"),
            pg_passwords=pg_passwords(args["seed"]),
            s3_bucket=s3_bucket,
            s3_endpoint=s3_endpoint,
            s3_region=s3_region,
            s3_access_key=args["s3_access_key"],
            s3_secret_key=args["s3_secret_key"],
        )

    cloud_init_inputs = pulumi.Output.all(
        vol_id=volume.id,
        ss_priv=ss_private_key,
        ss_pub=ss_public_cert,
        floating_ip_addr=floating_ip.ip_address,
        seed=master_seed,
        s3_access_key=s3_access_key,
        s3_secret_key=s3_secret_key,
    )
    cloud_init_data = cloud_init_inputs.apply(
        lambda args: create_cloud_init(args, GH_PAT)
    )

    ssh_key = hcloud.SshKey("ARIES", public_key=ARIES_PUB)

    # Create Firewall
    firewall = hcloud.Firewall(
        "web-firewall",
        rules=[
            hcloud.FirewallRuleArgs(
                direction="in",
                protocol="tcp",
                port="22",
                source_ips=["0.0.0.0/0", "::/0"],
            ),
            hcloud.FirewallRuleArgs(
                direction="in",
                protocol="tcp",
                port="80",
                source_ips=["0.0.0.0/0", "::/0"],
            ),
            hcloud.FirewallRuleArgs(
                direction="in",
                protocol="tcp",
                port="443",
                source_ips=["0.0.0.0/0", "::/0"],
            ),
            hcloud.FirewallRuleArgs(
                direction="in",
                protocol="icmp",
                source_ips=["0.0.0.0/0", "::/0"],
            ),
        ],
    )

    # 3. Define server
    # user_data and image only apply when the server is first created. After
    # that they are ignored here and delivered by the rebuild-server resource
    # below, which reinstalls this same server instead of replacing it: a
    # replacement has to win a new cx33 from Hetzner, and on 2026-08-20 there
    # was none.
    # delete_before_replace now only fires on deliberate changes (location,
    # ssh key); it keeps the graceful shutdown order below for those.
    cosmos_server = hcloud.Server(
        "cosmos",
        location="fsn1",
        public_nets=[hcloud.ServerPublicNetArgs(ipv4_enabled=True, ipv6_enabled=False)],
        firewall_ids=[firewall.id],
        ssh_keys=[ssh_key.id],
        server_type="cx33",
        image=SERVER_IMAGE,
        user_data=cloud_init_data,
        opts=pulumi.ResourceOptions(
            delete_before_replace=True,
            ignore_changes=["userData", "image"],
        ),
    )

    _ = hcloud.FloatingIpAssignment(
        "assign-terra",
        floating_ip_id=floating_ip.id,
        server_id=cosmos_server.id,
    )

    # 4. Attach Volume
    # automount=False because cloud-init mounts it itself (runcmd mount loop)
    volume_attachment = hcloud.VolumeAttachment(
        "data-volume-attachment",
        server_id=cosmos_server.id,
        volume_id=volume.id,
        automount=False,
    )

    connection = command.remote.ConnectionArgs(
        host=cosmos_server.ipv4_address,
        user="root",
        private_key=ARIES,
    )

    # Lifecycle Management:
    # Dependencies force Creation Order: Attachment -> Unmount Resource ->
    # Shutdown Resource
    # Destruction Order (Reverse): Shutdown Resource -> Unmount Resource ->
    # Attachment

    # 1. Unmount Volume (Ensures data consistency before detach)
    unmount_volume = command.remote.Command(
        "unmount-volume",
        connection=connection,
        create="ls -d /data",  # Verify mount exists on create
        delete="umount /data",
        opts=pulumi.ResourceOptions(depends_on=[volume_attachment]),
    )

    # 2. Graceful shutdown of services: the same sequence rebuild.py runs, so
    # a real replace stops pods and syncs too. Fails (and so aborts the
    # replace) if Postgres will not stop.
    # Do not rename or remove these two resources: deleting them from the
    # stack runs their delete hooks against the live server.
    shutdown_k3s = command.remote.Command(
        "shutdown-k3s",
        connection=connection,
        delete=STOP_SERVICES,
        opts=pulumi.ResourceOptions(depends_on=[unmount_volume]),
    )

    # 3. In-place rebuild (see rebuild.py)
    # Replaced -- and so re-run -- only when a trigger changes: new cloud-init,
    # new image, or a new server. A deploy that touches none of them leaves the
    # server alone. `./force-rebuild.sh` replaces it by hand when nothing
    # changed.
    # The hash leaves GH_PAT out: the token differs between machines and gets
    # rotated, and neither should make an unrelated push rebuild prod. A new
    # token reaches the server with the next rebuild.
    # update="true" matters: without it the provider re-runs `create` whenever
    # any other input changes (stdin does, with GH_PAT).
    # replace_on_changes is spelled out because the provider's docs say a
    # trigger runs `update` when one is set, while its SDK replaces
    # (pulumi/pulumi-command#855); if that is ever "fixed" towards the docs, a
    # cloud-init change would silently run `true`.
    cloud_init_sha = pulumi.Output.unsecret(
        cloud_init_inputs.apply(
            lambda args: hashlib.sha256(
                create_cloud_init(args, "<GH_PAT>").encode()
            ).hexdigest()
        )
    )
    command.local.Command(
        "rebuild-server",
        create="uv run --no-sync python rebuild.py",
        update="true",
        stdin=cloud_init_data,
        environment={
            "COSMOS_SERVER_ID": cosmos_server.id,
            "COSMOS_SERVER_IP": cosmos_server.ipv4_address,
            "COSMOS_IMAGE": SERVER_IMAGE,
        },
        triggers=[cloud_init_sha, SERVER_IMAGE, cosmos_server.id],
        add_previous_output_in_env=False,
        opts=pulumi.ResourceOptions(
            depends_on=[shutdown_k3s],
            replace_on_changes=["triggers[*]"],
        ),
    )

    pulumi.export("ip", cosmos_server.ipv4_address)

else:
    raise pulumi.RunError(
        f"stack '{STACK}' is not built yet -- staging arrives with the staging"
        " phase; valid stacks: dev, prod"
    )
