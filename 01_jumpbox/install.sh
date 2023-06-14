#!/usr/bin/env bash

set -e
set -u
set -o pipefail

source ../00_common/install.sh

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
: "${content_library_name?Must provide a content_libary_name}"
: "${jumpbox_ova_name?Must provide a jumpbox_ova_name}"
: "${jumpbox_ova_url?Must provide a jumpbox_ova_url}"

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

if ! govc library.ls "/${content_library_name}/${jumpbox_ova_name}" | grep ${jumpbox_ova_name} >&/dev/null; then
  #Upload OVA
  echo "Uploading OVA"

  govc library.import $content_library_name $jumpbox_ova_url

fi

if ! govc find vm -name "${vm_name}" | grep ${vm_name} >&/dev/null; then

  govc library.deploy \
    -ds "${datastore}" \
    -options=<(ytt -o json -f jumpbox.yml -v user_data="${user_data}" -v name="$vm_name" -v network="$vm_network") \
    "/${content_library_name}/${jumpbox_ova_name}" "${vm_name}"

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

fi

echo "Testing jumpbox connectivity..."

# wait until jumpbox is responding on port 22
until nc -vzw5 "$jumpbox_ip" 22; do sleep 5; done

ssh-keygen -R ${jumpbox_ip}
ssh-keyscan -H ${jumpbox_ip} >> ~/.ssh/known_hosts

ssh_public_key=$(cat ../01_jumpbox/.ssh/id_rsa.pub | base64)
ssh_private_key=$(cat ../01_jumpbox/.ssh/id_rsa | base64)
ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f addSSHKeyToJumphost); addSSHKeyToJumphost $ssh_private_key" "$ssh_public_key"
ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f); installTKGmTools"
ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f); installTerraform"

echo "SSH into jumpbox:"
echo " ssh -i .ssh/id_rsa ubuntu@${jumpbox_ip}"
echo
