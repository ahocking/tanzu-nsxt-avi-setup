#!/usr/bin/env bash

set -e
set -u
set -o pipefail

if [ -f ./jumpbox.config ]; then
  # shellcheck source=./jumpbox/jumpbox.config
  . ./jumpbox.config
fi

if ! [ -x "$(command -v govc)" ]; then
  echo 'govc must be installed in your PATH' 1>&2
  exit 1
fi

# Prereqs
: "${vc_password?Must provide a slot_password env var}"

# Defaults
: "${vcenter_host:=${vc_hostname}}"
: "${vm_name:=jumpbox}"

# Setup govc creds n' stuff
export \
  GOVC_INSECURE=1 \
  GOVC_USERNAME='administrator@vsphere.local' \
  GOVC_PASSWORD="${vc_password}" \
  GOVC_URL="${vcenter_host}"

# delete VM and disks
govc vm.destroy \
  "${vm_name}" \
