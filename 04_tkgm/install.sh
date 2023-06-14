#!/bin/bash -e
set -e
set -u
set -o pipefail

source ../00_common/install.sh
loadJumpboxConfig
loadTKGConfig
validateJumpboxKeyExists

# Prereqs
: "${jumpbox_ip?Must provide a jumpbox_ip env var}"
: "${vcc_user?Must provide a vcc_user env var}"
: "${vcc_pass?Must provide a vcc_pass env var}"
: "${slot_password?Must provide a slot_password env var}"
: "${h2o_domain?Must provide a h2o_domain env var}"
: "${vsphere_control_plane_endpoint?Must provide a vsphere_control_plane_endpoint env var}"
: "${tkgm_version?Must provide a tkgm_version env var}"

# Defaults
: "${vcenter_host:=vc01.${h2o_domain}}"
: "${os_name:=ubuntu}"
: "${cluster_plan:=dev}"
: "${base64_cacert:=''}"

ssh_public_key=$(cat ../01_jumpbox/.ssh/id_rsa.pub | base64)
ssh_private_key=$(cat ../01_jumpbox/.ssh/id_rsa | base64)
ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f addSSHKeyToJumphost); addSSHKeyToJumphost $ssh_private_key" "$ssh_public_key"
ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f); installTKGmTools"
ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f); installTerraform"
ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f installTKGm); installTKGm $vcc_user $vcc_pass $tkgm_version"
ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f uploadovas); uploadovas $vcenter_host '$slot_password' $vcc_user $vcc_pass $tkgm_version"

# case ${tkgm_version} in
#   1.*)
#     #NTP_SERVERS config variable available in 2.x
#     ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f addNTPOverlay); addNTPOverlay"
#     ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f addCert); addCert $base64_cacert"
#     ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f deployMgmtCluster); deployMgmtCluster $ssh_public_key $vcenter_host '$slot_password' $vsphere_control_plane_endpoint $os_name $cluster_plan";;
#   2.*)
#     ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f deployMgmtCluster2); deployMgmtCluster2 $ssh_public_key $vcenter_host '$slot_password' $vsphere_control_plane_endpoint $os_name $cluster_plan"
#     ssh ubuntu@${jumpbox_ip} -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f addCert); addCert $base64_cacert";;
# esac
