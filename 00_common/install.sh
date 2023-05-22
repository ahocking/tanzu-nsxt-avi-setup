#!/bin/bash -e
set -e
set -u
set -o pipefail

function scpFile {
  srcFile="$1"
  destFile="$2"
  scp -i ../01_jumpbox/.ssh/id_rsa "$srcFile" "ubuntu@${jumpbox_ip}:$destFile"
}

function scpDir {
  srcDir="$1"
  destDir="$2"
  scp -rp -i ../01_jumpbox/.ssh/id_rsa "$srcDir" "ubuntu@${jumpbox_ip}:$destDir"
}

function remoteExec {
  ssh "ubuntu@${jumpbox_ip}" -i ../01_jumpbox/.ssh/id_rsa "$(typeset -f); $*"
}

function loadJumpboxConfig {
  if [ -f ../01_jumpbox/jumpbox.config ]; then
    # shellcheck source=./01_jumpbox/jumpbox.config
    source ../01_jumpbox/jumpbox.config
  fi
}

function loadTKGConfig {
  if [ -f ../04_tkgm/tkgm.config ]; then
    # shellcheck source=./04_tkgm/tkgm.config
    source ../04_tkgm/tkgm.config
  fi
}

function validateJumpboxKeyExists {
  if [ ! -f ../01_jumpbox/.ssh/id_rsa.pub ]; then 
    echo "Ensure you have installed the jumphost prior to running"
    exit 1
  fi
}

function addSSHKeyToJumphost {
  echo "adding SSH key to jumphost"
  rm -f ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
  echo "$1" | base64 -d > ~/.ssh/id_rsa
  echo "$2" | base64 -d > ~/.ssh/id_rsa.pub
  chmod 400 ~/.ssh/id_rsa
}

function installOm {
  echo "Installing om"
  if [ ! -f  /usr/local/bin/om ]; then
    wget -q https://github.com/pivotal-cf/om/releases/download/7.8.2/om-linux-amd64-7.8.2
    sudo install om-linux-amd64-7.8.2 /usr/local/bin/om
    rm -f om-linux-amd64-7.8.2
  fi
}

function installJq {
  echo "Installing jq"
  if [ ! -f  /usr/local/bin/jq ]; then
    wget -q https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    sudo install jq-linux64 /usr/local/bin/jq
    rm -f jq-linux64
  fi
}

function installTerraform {
  echo "Installing terraform"
  terraform_version="1.4.5"
  if [ ! -f  /usr/local/bin/terraform ]; then
      # terraform_version="$1"
      wget -q https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip
      unzip terraform_${terraform_version}_linux_amd64.zip
      sudo install terraform /usr/local/bin/terraform
      rm -f terraform_${terraform_version}_linux_amd64.zip
      rm -f terraform
  fi
}

function installVcc {
  echo "Installing vcc"
  if [ ! -f  /usr/local/bin/vcc ]; then
      wget -q https://github.com/vmware-labs/vmware-customer-connect-cli/releases/download/v1.1.2/vcc-linux-v1.1.2
      sudo install vcc-linux-v1.1.2 /usr/local/bin/vcc
      rm -f vcc-linux-v1.1.2
  fi
}

function installGovc {
  echo "Installing govc"
  if [ ! -f  /usr/local/bin/govc ]; then
      wget -q https://github.com/vmware/govmomi/releases/download/v0.27.5/govc_Linux_x86_64.tar.gz
      tar -xf govc_Linux_x86_64.tar.gz
      sudo install govc /usr/local/bin/govc
      rm -f govc_Linux_x86_64.tar.gz
      rm -f govc
      rm -f CHANGELOG.md
      rm -f LICENSE.txt
      rm -f README.md
  fi
}

function installYtt {
  echo "Installing ytt"
  if [ ! -f  /usr/local/bin/ytt ]; then
      wget -q https://github.com/vmware-tanzu/carvel-ytt/releases/download/v0.41.1/ytt-linux-amd64
      sudo install ytt-linux-amd64 /usr/local/bin/ytt 
      rm -f ytt-linux-amd64
  fi
}

function installDocker {
  echo "Installing docker"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo apt-get -qq update
  sudo apt-get -qq install -y ca-certificates curl gnupg lsb-release jq docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker ubuntu
}

function installKind {
  echo "Installing kind"
  if [ ! -f  /usr/local/bin/kind ]; then
      wget -q https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64
      sudo install kind-linux-amd64 /usr/local/bin/kind
      rm -f kind-linux-amd64
  fi
}

function installTKGmTools {
  installVcc
  installGovc
  installYtt
  installDocker
  installKind
}

function installTKGm {
  echo "Installing Tanzu version $3"
  if [ ! -f  /usr/local/bin/tanzu ]; then
    export VCC_USER="$1"
    export VCC_PASS="$2"
    tkgm_version="$3"

    rm -rf cli 

    filename=tanzu-cli-bundle-linux-amd64.tar.gz
    #overwrite filename for older versions
    case ${tkgm_version} in
      1.4*)
        filename=tanzu-cli-bundle-linux-amd64.tar;;
    esac

    vcc download -p vmware_tanzu_kubernetes_grid -s tkg -v ${tkgm_version} -f 'tanzu-cli-bundle-linux-amd64.*' --accepteula
    tar -xf $HOME/vcc-downloads/$filename
    tanzu_cli=$(find . -name tanzu-core-linux_amd64)
    sudo install $tanzu_cli /usr/local/bin/tanzu

    case ${tkgm_version} in
      1.4*)
        tanzu plugin install all -l cli;;
      *)
        tanzu init;; 
    esac
    tanzu plugin list
    rm -rf cli
  fi

  echo "Installing kubectl"
  if [ ! -f  /usr/local/bin/kubectl ]; then
    export VCC_USER="$1"
    export VCC_PASS="$2"
    vcc download -p vmware_tanzu_kubernetes_grid -s tkg -v ${tkgm_version} -f 'kubectl-linux-*' --accepteula
    gunzip $HOME/vcc-downloads/kubectl-linux*.gz
    kubectlcli=$(find . -name kubectl-linux*)
    sudo install $kubectlcli /usr/local/bin/kubectl
    rm -f $kubectlcli
  fi

  if [ -f  /usr/local/bin/kubectl ]; then
    echo "Adding bash completion"
    echo 'source <(kubectl completion bash)' >>~/.bashrc
    echo 'alias k=kubectl' >>~/.bashrc
    echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
  fi
}

function uploadovas {
  export GOVC_URL=$1
  export GOVC_PASSWORD=$2
  export VCC_USER="$3"
  export VCC_PASS="$4"
  export TKGM_VERSION="$5"
  export GOVC_INSECURE=1
  export GOVC_USERNAME=administrator@vsphere.local
  export GOVC_DATASTORE=vsanDatastore
  export GOVC_NETWORK="user-workload"
  export GOVC_RESOURCE_POOL='*/Resources'
  
  ova_version="null"
  case ${TKGM_VERSION} in
      1.4*)
        ova_version="*v1.21.*.ova";;
      1.5*)
        ova_version="*v1.22.*.ova";;
      1.6*)
        ova_version="*v1.23.*.ova";;
      2.1*)
        ova_version="*v1.24.*.ova";;
      *)
        echo "Version ${TKGM_VERSION} not yet supported in script!"
        exit 1;;
  esac

  vcc download -p vmware_tanzu_kubernetes_grid -s tkg -v ${TKGM_VERSION} -f $ova_version --accepteula
  importSpecs=$(mktemp -d)
  directory=$HOME/vcc-downloads
  find "$directory" -name "*.ova"|while read fname; do
    specname=$(echo "${fname/$directory\//}")
    export releasename=$(echo "${specname%-tkg.2*}")
    templates=$(govc find vm -name ${releasename})
    if [ -z "$templates" ]; then
      govc import.spec $fname | jq '.MarkAsTemplate = true' |  jq '.NetworkMapping[0].Network = "user-workload"' | jq '.Name = env.releasename' >  $importSpecs/$specname.yaml
      govc import.ova -options=$importSpecs/$specname.yaml $fname
    fi 
  done
}

function addNTPOverlay {
  if [ ! -f  /usr/local/bin/tanzu ]; then
    echo "Skipping adding NTP overlay as tanzu cli is not installed"
  else
    echo "adding NTP overlay with H2O time servers"
cat << EOF > ~/.config/tanzu/tkg/providers/infrastructure-vsphere/ytt/ntp-overlay.yaml
#@ load("@ytt:overlay", "overlay")
#@ load("@ytt:data", "data")

#@overlay/match by=overlay.subset({"kind":"KubeadmControlPlane"})
---
spec:
  kubeadmConfigSpec:
    #@overlay/match missing_ok=True
    ntp:
      #@overlay/match missing_ok=True
      enabled: true
      #@overlay/match missing_ok=True
      servers:
      - time1.oc.vmware.com
      - time2.oc.vmware.com
      - time3.oc.vmware.com
      - time4.oc.vmware.com

#@overlay/match by=overlay.subset({"kind":"KubeadmConfigTemplate"}),expects="1+"
---
spec:
  template:
    spec:
      #@overlay/match missing_ok=True
      ntp:
        #@overlay/match missing_ok=True
        enabled: true
        #@overlay/match missing_ok=True
        servers:
        - time1.oc.vmware.com
        - time2.oc.vmware.com
        - time3.oc.vmware.com
        - time4.oc.vmware.com
EOF
  fi
}

function addCert {
  if [[ -z "$1" ]];    then
    echo "skipping custom ca cert"
  else
    if [ ! -f  /usr/local/bin/tanzu ]; then
      echo "Skipping adding ca overlay as tanzu cli is not installed"
    else
      echo "adding CA"
      echo $1 | base64 -d > ~/.config/tanzu/tkg/providers/infrastructure-vsphere/ytt/tkg-custom-ca.pem
      echo "adding CA overlay"
cat << EOF > ~/.config/tanzu/tkg/providers/infrastructure-vsphere/ytt/ca-overlay.yaml
#@ load("@ytt:overlay", "overlay")
#@ load("@ytt:data", "data")

#! This ytt overlay adds additional custom CA certificates on TKG cluster nodes, so containerd and other tools trust these CA certificates.
#! It works when using Photon or Ubuntu as the TKG node template on all TKG infrastructure providers.

#! Trust your custom CA certificates on all Control Plane nodes.
#@overlay/match by=overlay.subset({"kind":"KubeadmControlPlane"})
---
spec:
  kubeadmConfigSpec:
    #@overlay/match missing_ok=True
    files:
      #@overlay/append
      - content: #@ data.read("tkg-custom-ca.pem")
        owner: root:root
        permissions: "0644"
        path: /etc/ssl/certs/tkg-custom-ca.pem
    #@overlay/match missing_ok=True
    preKubeadmCommands:
      #! For Photon OS
      #@overlay/append
      - '! which rehash_ca_certificates.sh 2>/dev/null || rehash_ca_certificates.sh'
      #! For Ubuntu
      #@overlay/append
      - '! which update-ca-certificates 2>/dev/null || (mv /etc/ssl/certs/tkg-custom-ca.pem /usr/local/share/ca-certificates/tkg-custom-ca.crt && update-ca-certificates)'

#! Trust your custom CA certificates on all worker nodes.
#@overlay/match by=overlay.subset({"kind":"KubeadmConfigTemplate"}), expects="1+"
---
spec:
  template:
    spec:
      #@overlay/match missing_ok=True
      files:
        #@overlay/append
        - content: #@ data.read("tkg-custom-ca.pem")
          owner: root:root
          permissions: "0644"
          path: /etc/ssl/certs/tkg-custom-ca.pem
      #@overlay/match missing_ok=True
      preKubeadmCommands:
        #! For Photon OS
        #@overlay/append
        - '! which rehash_ca_certificates.sh 2>/dev/null || rehash_ca_certificates.sh'
        #! For Ubuntu
        #@overlay/append
        - '! which update-ca-certificates 2>/dev/null || (mv /etc/ssl/certs/tkg-custom-ca.pem /usr/local/share/ca-certificates/tkg-custom-ca.crt && update-ca-certificates)'
EOF
    fi
  fi 
}

function deployMgmtCluster {
  if tanzu mc get > /dev/null 2>&1 ; then
     echo "Management cluster already exists"
  else
     echo "Creating managment cluster"
  mgmt_cluster=./mgmt-cluster-template.yaml
cat << EOF > $mgmt_cluster
#@ load("@ytt:data", "data")
---
AVI_CA_DATA_B64: ""
AVI_CLOUD_NAME: ""
AVI_CONTROL_PLANE_HA_PROVIDER: ""
AVI_CONTROLLER: ""
AVI_DATA_NETWORK: ""
AVI_DATA_NETWORK_CIDR: ""
AVI_ENABLE: "false"
AVI_LABELS: ""
AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_CIDR: ""
AVI_MANAGEMENT_CLUSTER_VIP_NETWORK_NAME: ""
AVI_PASSWORD: ""
AVI_SERVICE_ENGINE_GROUP: ""
AVI_USERNAME: ""
CLUSTER_CIDR: 100.96.0.0/11
CLUSTER_PLAN: #@ data.values.cluster_plan
ENABLE_AUDIT_LOGGING: "false"
ENABLE_CEIP_PARTICIPATION: "false"
ENABLE_MHC: "true"
IDENTITY_MANAGEMENT_TYPE: none
INFRASTRUCTURE_PROVIDER: vsphere
LDAP_BIND_DN: ""
LDAP_BIND_PASSWORD: ""
LDAP_GROUP_SEARCH_BASE_DN: ""
LDAP_GROUP_SEARCH_FILTER: ""
LDAP_GROUP_SEARCH_GROUP_ATTRIBUTE: ""
LDAP_GROUP_SEARCH_NAME_ATTRIBUTE: cn
LDAP_GROUP_SEARCH_USER_ATTRIBUTE: DN
LDAP_HOST: ""
LDAP_ROOT_CA_DATA_B64: ""
LDAP_USER_SEARCH_BASE_DN: ""
LDAP_USER_SEARCH_FILTER: ""
LDAP_USER_SEARCH_NAME_ATTRIBUTE: ""
LDAP_USER_SEARCH_USERNAME: userPrincipalName
OIDC_IDENTITY_PROVIDER_CLIENT_ID: ""
OIDC_IDENTITY_PROVIDER_CLIENT_SECRET: ""
OIDC_IDENTITY_PROVIDER_GROUPS_CLAIM: ""
OIDC_IDENTITY_PROVIDER_ISSUER_URL: ""
OIDC_IDENTITY_PROVIDER_NAME: ""
OIDC_IDENTITY_PROVIDER_SCOPES: ""
OIDC_IDENTITY_PROVIDER_USERNAME_CLAIM: ""
OS_ARCH: amd64
OS_NAME: #@ data.values.os_name
SERVICE_CIDR: 100.64.0.0/13
TKG_HTTP_PROXY_ENABLED: "false"
VSPHERE_CONTROL_PLANE_DISK_GIB: "40"
VSPHERE_CONTROL_PLANE_ENDPOINT: #@ data.values.vsphere_control_plane_endpoint
VSPHERE_CONTROL_PLANE_MEM_MIB: "8192"
VSPHERE_CONTROL_PLANE_NUM_CPUS: "2"
VSPHERE_DATACENTER: /vc01
VSPHERE_DATASTORE: /vc01/datastore/vsanDatastore
VSPHERE_FOLDER: /vc01/vm
VSPHERE_NETWORK: /vc01/network/user-workload
VSPHERE_PASSWORD: #@ data.values.vsphere_password
VSPHERE_RESOURCE_POOL: /vc01/host/vc01cl01/Resources
VSPHERE_SERVER: #@ data.values.vsphere_host
VSPHERE_SSH_AUTHORIZED_KEY: #@ data.values.public_ssh_key
VSPHERE_INSECURE: "true"
VSPHERE_USERNAME: administrator@vsphere.local
VSPHERE_WORKER_DISK_GIB: "40"
VSPHERE_WORKER_MEM_MIB: "8192"
VSPHERE_WORKER_NUM_CPUS: "2"
DEPLOY_TKG_ON_VSPHERE7: true
EOF
    public_ssh_key="$(echo $1 | base64 -d)"
    vsphere_host="$2"
    vsphere_password="$3"
    vsphere_control_plane_endpoint="$4"
    os_name="$5"
    cluster_plan="$6"

    rm -f management-cluster.yaml
    ytt --ignore-unknown-comments -f $mgmt_cluster -v cluster_plan="${cluster_plan}" -v os_name="${os_name}" -v public_ssh_key="${public_ssh_key}" -v vsphere_host="${vsphere_host}" -v vsphere_password="${vsphere_password}" -v vsphere_control_plane_endpoint="${vsphere_control_plane_endpoint}" > management-cluster.yaml
    tanzu management-cluster create -f management-cluster.yaml
    rm -f $mgmt_cluster
  fi
}

function deployMgmtCluster2 {
  if tanzu mc get > /dev/null 2>&1 ; then
     echo "Management cluster already exists"
  else
     echo "Creating managment cluster"
  mgmt_cluster=./mgmt-cluster-template.yaml
cat << EOF > $mgmt_cluster
#@ load("@ytt:data", "data")
---

AVI_ENABLE: "false"
CLUSTER_CIDR: 100.96.0.0/11
CLUSTER_PLAN: #@ data.values.cluster_plan
ENABLE_AUDIT_LOGGING: "false"
ENABLE_CEIP_PARTICIPATION: "false"
ENABLE_MHC: "true"
IDENTITY_MANAGEMENT_TYPE: none
INFRASTRUCTURE_PROVIDER: vsphere
NTP_SERVERS: time1.oc.vmware.com, time2.oc.vmware.com, time3.oc.vmware.com, time4.oc.vmware.com
OS_ARCH: amd64
OS_NAME: #@ data.values.os_name
SERVICE_CIDR: 100.64.0.0/13
TKG_HTTP_PROXY_ENABLED: "false"
VSPHERE_CONTROL_PLANE_DISK_GIB: "40"
VSPHERE_CONTROL_PLANE_ENDPOINT: #@ data.values.vsphere_control_plane_endpoint
VSPHERE_CONTROL_PLANE_MEM_MIB: "8192"
VSPHERE_CONTROL_PLANE_NUM_CPUS: "2"
VSPHERE_DATACENTER: /vc01
VSPHERE_DATASTORE: /vc01/datastore/vsanDatastore
VSPHERE_FOLDER: /vc01/vm
VSPHERE_NETWORK: /vc01/network/user-workload
VSPHERE_PASSWORD: #@ data.values.vsphere_password
VSPHERE_RESOURCE_POOL: /vc01/host/vc01cl01/Resources
VSPHERE_SERVER: #@ data.values.vsphere_host
VSPHERE_SSH_AUTHORIZED_KEY: #@ data.values.public_ssh_key
VSPHERE_INSECURE: "true"
VSPHERE_USERNAME: administrator@vsphere.local
VSPHERE_WORKER_DISK_GIB: "40"
VSPHERE_WORKER_MEM_MIB: "8192"
VSPHERE_WORKER_NUM_CPUS: "2"
DEPLOY_TKG_ON_VSPHERE7: true
EOF
    public_ssh_key="$(echo $1 | base64 -d)"
    vsphere_host="$2"
    vsphere_password="$3"
    vsphere_control_plane_endpoint="$4"
    os_name="$5"
    cluster_plan="$6"

    rm -f management-cluster.yaml
    ytt --ignore-unknown-comments -f $mgmt_cluster -v cluster_plan="${cluster_plan}" -v os_name="${os_name}" -v public_ssh_key="${public_ssh_key}" -v vsphere_host="${vsphere_host}" -v vsphere_password="${vsphere_password}" -v vsphere_control_plane_endpoint="${vsphere_control_plane_endpoint}" > management-cluster.yaml
    tanzu management-cluster create -f management-cluster.yaml
    rm -f $mgmt_cluster
  fi
}

function deployOpsman {
  local vcenter_host="$1"
  local slot_password="$2"
  local vcenter_pool="$3"
  local opsman_ova="$4"
  local opsman_network="$5"

  # Deploy Opsman VM
  export \
    GOVC_URL="${vcenter_host}" \
    GOVC_INSECURE=1 \
    GOVC_USERNAME='administrator@vsphere.local' \
    GOVC_PASSWORD="${slot_password}"

  returnsSomething() {
    local bytes
    bytes="$( "$@" | wc -c )"

    [[ "$bytes" -ne 0 ]]
  }

  if returnsSomething govc pool.info "/vc01/host/vc01cl01/Resources/$vcenter_pool" ; then
    echo >&2 "Pool $vcenter_pool already exists, skipping creation"
  else
    govc pool.create "/vc01/host/vc01cl01/Resources/$vcenter_pool"
  fi

  if returnsSomething govc vm.info ops-manager ; then
    echo >&2 "Opsmanager VM already exists, skipping creation"
  else
    # generate the VApp properties file for the opsman OVA
    public_ssh_key=$(cat ~/.ssh/id_rsa.pub)
cat << EOF > /tmp/opsman.json
{
    "DiskProvisioning": "flat",
    "IPAllocationPolicy": "dhcpPolicy",
    "IPProtocol": "IPv4",
    "PropertyMapping": [
      {
        "Key": "ip0",
        "Value": "192.168.1.3"
      },
      {
        "Key": "netmask0",
        "Value": "255.255.255.0"
      },
      {
        "Key": "gateway",
        "Value": "192.168.1.1"
      },
      {
        "Key": "DNS",
        "Value": "10.79.2.5,10.79.2.6"
      },
      {
        "Key": "ntp_servers",
        "Value": "time1.oc.vmware.com,time2.oc.vmware.com"
      },
      {
        "Key": "public_ssh_key",
        "Value": "$public_ssh_key"
      },
      {
        "Key": "custom_hostname",
        "Value": ""
      }
    ],
    "NetworkMapping": [
      {
        "Name": "Network 1",
        "Network": "$opsman_network"
      }
    ],
    "Annotation": "Tanzu Ops Manager installs and manages products and services.",
    "MarkAsTemplate": false,
    "PowerOn": false,
    "InjectOvfEnv": false,
    "WaitForIP": false,
    "Name": null
}
EOF
    govc import.ova -name 'ops-manager' -pool "$vcenter_pool" --options /tmp/opsman.json "${opsman_ova}"
    govc vm.power -on 'ops-manager'
    rm /tmp/opsman.json
  fi
}

function configureAndDeployBOSH {
  local vcenter_host="$1"
  local nsxt_host="$2"
  local opsman_host="$3"
  local slot_password="$4"

  # wait until opsman is responding on port 443
  until nc -vzw5 "$opsman_host" 443; do sleep 5; done

  # Set om connection info
  export \
    OM_USERNAME='admin' \
    OM_PASSWORD="${slot_password}" \
    OM_DECRYPTION_PASSPHRASE="${slot_password}" \
    OM_SKIP_SSL_VALIDATION='true' \
    OM_TARGET="${opsman_host}"

  # Configure Opsman auth
  om -o 360 configure-authentication \
    --username admin \
    --password "${slot_password}" \
    --decryption-passphrase "${slot_password}"

  # Configure BOSH director and deploy
  openssl s_client -showcerts -connect "${nsxt_host}:443" < /dev/null 2> /dev/null | openssl x509 > /tmp/nsxt_host.pem
  om configure-director \
    --config /tmp/director.yml \
    --var "iaas-configurations_0_nsx_address=${nsxt_host}" \
    --var "iaas-configurations_0_nsx_ca_certificate=$(cat /tmp/nsxt_host.pem)" \
    --var "iaas-configurations_0_nsx_password=${slot_password}" \
    --var "iaas-configurations_0_vcenter_host=${vcenter_host}" \
    --var "iaas-configurations_0_vcenter_password=${slot_password}"

  om apply-changes \
    --skip-deploy-products

  # Cleanup
  rm /tmp/nsxt_host.pem
  rm /tmp/director.yml
}

function createOpsmanDirEnv {
  cat << EOF > .envrc
#!/bin/bash -e

export OM_USERNAME='admin'
export OM_PASSWORD="${slot_password}"
export OM_DECRYPTION_PASSPHRASE="${slot_password}"
export OM_SKIP_SSL_VALIDATION='true'
export OM_TARGET="${opsman_host}"
export OM_CONNECT_TIMEOUT='30'

# Set the BOSH env vars from opsman
eval "\$(om bosh-env -i "../jumpbox/.ssh/id_rsa")"

export GOVC_URL="${vcenter_host}"
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD="${slot_password}"
export GOVC_INSECURE=true
EOF
}
