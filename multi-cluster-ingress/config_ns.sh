#!/usr/bin/env bash

set -e # bail out early if any command fails
set -u # fail if we hit unset variables
set -o pipefail # fail if any component of any pipe fails


kubectl config use-context gke-us
kubectl apply -f namespace.yaml
kubectl apply -f deploy.yaml
kubectl get deployment --namespace zoneprinter

kubectl config use-context gke-eu
kubectl apply -f namespace.yaml
kubectl apply -f deploy.yaml
kubectl get deployment --namespace zoneprinter

kubectl config use-context gke-uk
kubectl apply -f namespace.yaml
kubectl apply -f deploy.yaml
kubectl get deployment --namespace zoneprinter
