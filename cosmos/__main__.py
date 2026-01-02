"""A Python Pulumi program"""

import os
import pulumi_hcloud as hcloud
import pathlib

# provision GH_PAT and HCLOUD_TOKEN from environment
# locally that's in a .envrc
# in GHA it's a Github Secret
with pathlib.Path("cloud-init.yaml").open() as file:
    CLOUD_INIT = file.read().format(
        gh_pat=os.environ.get("GH_PAT"), hcloud_token=os.environ.get("HCLOUD_TOKEN")
    )

ssh_key = hcloud.SshKey("ARIES", public_key=os.environ.get("ARIES_PUB"))

# Setup instance
## Setup a floating IP
floating_ip = hcloud.FloatingIp.get(resource_name="terra-incognita", id="63752554")

## Define server
test_server = hcloud.Server(
    "test-server",
    datacenter="fsn1-dc14",
    public_nets=[hcloud.ServerPublicNetArgs(ipv4_enabled=True, ipv6_enabled=False)],
    ssh_keys=[ssh_key.id],
    server_type="cx33",
    image="ubuntu-24.04",
    user_data=CLOUD_INIT,  # this sets everything up
)

## Attach volume to server
k3s_volume = hcloud.Volume(
    resource_name="k3s-volume",
    automount=False,
    delete_protection=True,
    format="ext4",
    size=60,
    server_id=test_server.id,
)


## Connect the server to the IP
_ = hcloud.FloatingIpAssignment(
    "assign_terra",
    floating_ip_id=floating_ip.id,
    server_id=test_server.id,
)
