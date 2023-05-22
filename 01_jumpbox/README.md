# Jumpbox
Automation to create a jumpbox or bastion host with Tanzu tools available in an H2O environment. 
The jumpbox is prerequisite for other platform installation helpers.

This downloads and installs kubectl with the vsphere plugin from your instance of H20, and
the tanzu cli (version v0.11.4) from github. After install, it will also set
the kubectl config for the ubuntu user and run tanzu init.

## Running
This script assumes you're running it from a Mac or Linux workstation connected to the VMware VPN.
Before running the jumpbox `install.sh` ensure you have [govc] and [ytt] in your PATH.

The install script requires the following environment variables to be set
which can be set from the command line or optionally by populating a file named `jumpbox.config`
in the `jumpbox` directory using the below template:

[govc]: https://github.com/vmware/govmomi/releases
[ytt]: https://github.com/vmware-tanzu/carvel-ytt/releases

```bash
# Required
slot_password='supersecret'
h2o_domain='h2o-11-255.h2o.vmware.com'
jumpbox_ip='10.220.41.199'
jumpbox_gateway='10.220.41.222'

# Optional - overrides defaults
jumpbox_netmask='255.255.255.192'
jumpbox_dns='10.79.2.5,10.79.2.6'
wcp='vc01cl01-wcp.h2o-37-252.h2o.vmware.com'
vm_name='jumpbox'
vm_network='user-workload'
root_disk_size='50G'
datastore='vsanDatastore'
ram='2048'
```

The slot password is your h2o environment password used everywhere. The jumpbox
IP should come from the `user-workload` network range and the jumpbox subnet
gateway should be the default gateway for that network. The wcp is the default 
supervisor cluster under virtual resources.

To create the jumpbox run:

```bash
$ cd jumpbox && ./install.sh
```

This will download the latest Ubuntu Focal OVA and spin up a jumpbox VM in vSphere
at the specified IP.

### Which IPs, WAT?

Alternatively, when you have the [h2o CLI] installed, you can pull the IPs
and other configs automatically, and not use your `./jumpbox.config` at all (if
you don't need any of the optional settings or don't need to override any of
the default settings):

```bash
# override some default configs if needed
# you can also keep that file empty or delete it
cat <<'EOF' >jumpbox.config
root_disk_size='200G'
vm_name='tas-bastion'
ram='6144'
EOF

# pull and source data from h2o
. <(../pull-h2o-data.sh h2o-2-489 jumpbox)

# do the thing
./install.sh
```

[h2o CLI]: https://build-artifactory.eng.vmware.com/artifactory/h2o-local/cli/2.0.0/linux/h2o


## Usage

To SSH into the jumpbox use the key that the install script generated in the jumpbox .ssh directory.

```bash
$ ssh -i .ssh/id_rsa ubuntu@yourjumpboxip
```
