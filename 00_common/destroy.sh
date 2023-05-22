#!/bin/bash -e
set -e
set -u
set -o pipefail

function deleteTKGVMs {
  vms=$(govc find vm -name 'tkg-*')
  for vm in ${vms}
  do
    echo "Destroying VM: $vm"
    govc vm.destroy $vm 
  done

  vms=$(govc find vm -name '*-control-plane-*')
  for vm in ${vms}
  do
    echo "Destroying VM: $vm"
    govc vm.destroy $vm 
  done

  vms=$(govc find vm -name '*-md-*')
  for vm in ${vms}
  do
    echo "Destroying VM: $vm"
    govc vm.destroy $vm 
  done
}

function removeVMTemplates {
  templates=$(govc find vm -name 'photon-3-*')
  for template in ${templates}
  do
    echo "Removing template VM: $template"
    govc vm.destroy $template 
  done

  templates=$(govc find vm -name 'ubuntu-2004-*')
  for template in ${templates}
  do
    echo "Removing template VM: $template"
    govc vm.destroy $template 
  done
}

function deleteJumphost {
  vms=$(govc find . -type m -guest.ipAddress "$1")
  for vm in ${vms}
  do
    echo "Removing jumphost VM: $vm"
    govc vm.destroy $vm 
  done
}
# Prereqs
: "${jumpbox_ip?Must provide a jumpbox_ip env var}"
: "${slot_password?Must provide a slot_password env var}"
: "${h2o_domain?Must provide a h2o_domain env var}"

# Defaults
: "${vcenter_host:=vc01.${h2o_domain}}"


export GOVC_URL=$vcenter_host
export GOVC_PASSWORD=$slot_password
export GOVC_INSECURE=1
export GOVC_USERNAME=administrator@vsphere.local
export GOVC_DATASTORE=vsanDatastore
export GOVC_NETWORK="user-workload"
export GOVC_RESOURCE_POOL='*/Resources'