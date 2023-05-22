# Jumpbox

Automation to install TKGm management cluster without AVI in H2O

## Running

The install script requires the following environment variables to be set
which can be set from the command line or optionally by populating a file named `tkgm.config`
in the `tkgm` directory using the below template:

```bash
# Required
vcc_user='customer connect user name' 
vcc_pass='customer connect password' 
vsphere_control_plane_endpoint='10.220.2.162'
tkgm_version='2.1.0' #tested 1.4.0-2.1.0
# inherited from jumpbox config
slot_password='supersecret'
h2o_domain='h2o-11-255.h2o.vmware.com'
jumpbox_ip='10.220.2.161'
os_name='photon | ubuntu'
cluster_plan='dev | prod'
base64_cacert=<base64 encoded pem file contents of cacert>
```

To deploy tkgm after you have installed jumphost via jumphost directory:

```bash
$ cd tkgm && ./install.sh
```

