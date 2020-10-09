#!/usr/bin/env bash

set -e # bail out early if any command fails
set -u # fail if we hit unset variables
set -o pipefail # fail if any component of any pipe fails

# Which ever is the main cluster
kubectl config use-context gke-uk

kubectl apply -f mcs.yaml
kubectl get mcs -n zoneprinter
kubectl apply -f mci.yaml

kubectl describe mci zone-ingress -n zoneprinter
echo "kubectl describe mci zone-ingress -n zoneprinter"
