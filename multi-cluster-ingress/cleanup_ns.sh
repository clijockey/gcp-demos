#!/usr/bin/env bash

set -e # bail out early if any command fails
set -u # fail if we hit unset variables
set -o pipefail # fail if any component of any pipe fails


# Remove the multi-cluster config
echo "🔥 Removing the multi-cluster config .... the pods and namespaces will remain!"
kubectl delete -f mci.yaml
kubectl delete -f mcs.yaml

