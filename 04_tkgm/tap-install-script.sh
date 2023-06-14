#!/bin/bash

set -e
# Set Environmental Variables
echo "Setting environmental variables..."
export IMGPKG_REGISTRY_HOSTNAME=harbor.h2o-2-10553.h2o.vmware.com
export IMGPKG_REGISTRY_USERNAME=admin
export IMGPKG_REGISTRY_PASSWORD=password
export TAP_VERSION=1.5.0
export REGISTRY_CA_PATH=/home/ubuntu/utils/certs/harbor.h2o-2-10553.h2o.vmware.com.crt
export INSTALL_REPO=tap-packages
export TAP_VALUES_PATH=/home/ubuntu/utils/apps/tap/configs/tap-full-github.yaml

# Check if tap-packages project exists
echo "Checking if tap-packages project exists..."
response=$(curl -s -o /dev/null -w "%{http_code}" -u "$IMGPKG_REGISTRY_USERNAME:$IMGPKG_REGISTRY_PASSWORD" \
  "https://$IMGPKG_REGISTRY_HOSTNAME/api/v2.0/projects/tap-packages" 2>/dev/null)

if [ "$response" -eq 200 ]; then
  echo "tap-packages project already exists. Skipping project creation."
fi

# Create Public Harbor Project
echo "Creating public Harbor project..."
curl -u "$IMGPKG_REGISTRY_USERNAME:$IMGPKG_REGISTRY_PASSWORD" -X POST \
  "https://$IMGPKG_REGISTRY_HOSTNAME/api/v2.0/projects" \
  -H 'Content-Type: application/json' \
  -d '{
    "project_name": "tap-packages",
    "public": true
  }'

# Pull TAP Images and package to TAR bundle
echo "Pulling TAP images and packaging to TAR bundle..."
imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:$TAP_VERSION --to-repo $IMGPKG_REGISTRY_HOSTNAME/$INSTALL_REPO/tap-packages

# Push images to Internal repo

# Check if tap-install namespace exists
echo "Checking if tap-install namespace exists..."
if ! kubectl get ns tap-install >/dev/null 2>&1; then
  # Create tap-install namespace
  echo "Creating tap-install namespace..."
  kubectl create ns tap-install
else
  echo "tap-install namespace already exists. Skipping namespace creation."
fi

# Create registry secret for TAP Install
echo "Creating registry secret for TAP Install..."
tanzu secret registry add tap-registry \
    --server   $IMGPKG_REGISTRY_HOSTNAME \
    --username $IMGPKG_REGISTRY_USERNAME \
    --password $IMGPKG_REGISTRY_PASSWORD \
    --namespace tap-install \
    --export-to-all-namespaces \
    --yes

# Check if tanzu-tap-repository exists
echo "Checking if tanzu-tap-repository exists..."
if ! tanzu package repository get tanzu-tap-repository --namespace tap-install >/dev/null 2>&1; then
  # Add the tap repo to tanzu
  echo "Adding the tap repo to tanzu..."
  tanzu package repository add tanzu-tap-repository \
    --url $IMGPKG_REGISTRY_HOSTNAME/tap-packages/tap-packages:$TAP_VERSION \
    --namespace tap-install
else
  echo "tanzu-tap-repository already exists. Skipping repository addition."
fi

# Verify Package repo installed correctly
echo "Verifying Package repo installation..."
tanzu package repository get tanzu-tap-repository --namespace tap-install

# Verify App package is available
echo "Verifying App package availability..."
tanzu package available list tap.tanzu.vmware.com --namespace tap-install

# Install TAP using tap-full values file
echo "Installing TAP using tap-full values file..."
tanzu package install tap -p tap.tanzu.vmware.com -v $TAP_VERSION --values-file $TAP_VALUES_PATH -n tap-install

## Uninstall TAP
# tanzu package installed delete tap --namespace tap-install