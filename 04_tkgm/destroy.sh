#!/bin/bash -e
set -e
set -u
set -o pipefail

source ../common/install.sh
loadJumpboxConfig
source ../common/destroy.sh

deleteTKGVMs
removeVMTemplates
deleteJumphost $jumpbox_ip
