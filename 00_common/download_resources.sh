#!/bin/bash -e
set -e
set -u
set -o pipefail

DIR="$( cd "$( dirname "$0" )" && pwd )"

downloads_dir="$DIR/../artifact-downloads"

mkdir -p ${downloads_dir}

