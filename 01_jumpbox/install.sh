#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ -f ./jumpbox.config ]; then
  # shellcheck source=./jumpbox/jumpbox.config
  . ./jumpbox.config
fi

if ! [ -x "$(command -v ytt)" ]; then
  echo 'ytt must be installed in your PATH' 1>&2
  exit 1
fi

if ! [ -x "$(command -v govc)" ]; then
  echo 'govc must be installed in your PATH' 1>&2
  exit 1
fi

# Prereqs
: "${vc_password?Must provide a slot_password env var}"
: "${vc_hostname?Must provide a domain env var}"
: "${jumpbox_ip?Must provide a jumpbox_ip env var}"
: "${jumpbox_gateway?Must provide a jumpbox_gateway env var}"

# Defaults
: "${jumpbox_netmask:=255.255.255.192}"
: "${wcp:=}"
: "${vcenter_host:=${vc_hostname}}"
: "${jumpbox_dns:=10.79.2.5,10.79.2.6}"
: "${vm_name:=jumpbox}"
: "${vm_network:=user-workload}"
: "${root_disk_size:=50G}"
: "${datastore:=vsanDatastore}"
: "${ram:=2048}"

if [ ! -f ./.ssh/id_rsa ]; then
# Generate SSH key for the jumpbox
mkdir -p ./.ssh
< /dev/zero ssh-keygen -b 2048 -t rsa -m PEM -f ./.ssh/id_rsa -q -N ''
fi

# Create the cloud-init config for the OVA
user_data="$(
  ytt --ignore-unknown-comments -f user-data.yml \
  -v public_ssh_key="$(cat .ssh/id_rsa.pub)" \
  -v vc_password="${vc_password}" \
  -v wcp="${wcp}"
)"

# Setup govc creds n' stuff
export \
  GOVC_INSECURE=1 \
  GOVC_USERNAME='administrator@vsphere.local' \
  GOVC_PASSWORD="${vc_password}" \
  GOVC_URL="${vcenter_host}"

# Create the VM
govc import.ova \
  -ds "${datastore}" \
  -name "${vm_name}" \
  -options=<(ytt -o json -f jumpbox.yml -v user_data="${user_data}" -v name="$vm_name" -v network="$vm_network")  \
  https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.ova

# Update ram
govc vm.change \
  -vm "${vm_name}" \
  -m "${ram}"

# resize the root disk
govc vm.disk.change -vm "${vm_name}" -disk.label "Hard disk 1" -size "${root_disk_size}"

# set vm ip
govc vm.customize \
  -vm "${vm_name}" \
  -ip "${jumpbox_ip}" \
  -netmask "${jumpbox_netmask}" \
  -dns-server "${jumpbox_dns}" \
  -gateway "${jumpbox_gateway}"

# power on VM
govc vm.power \
  -on "${vm_name}"

# wait until jumpbox is responding on port 22
until nc -vzw5 "$jumpbox_ip" 22; do sleep 5; done

echo "SSH into jumpbox:"
echo " ssh -i .ssh/id_rsa ubuntu@${jumpbox_ip}"
echo
