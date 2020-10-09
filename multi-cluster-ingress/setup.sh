#!/usr/bin/env bash

set -e # bail out early if any command fails
set -u # fail if we hit unset variables
set -o pipefail # fail if any component of any pipe fails


# Ensure the API's are enabled
echo "🚀 Enable required GCP API's ... "
gcloud services enable gkehub.googleapis.com
gcloud services enable anthos.googleapis.com
gcloud services enable multiclusteringress.googleapis.com

# Create EU Cluster
echo "🇪🇺 Create a GKE cluster in Europe called gke-eu ..."
gcloud container clusters create gke-eu \
  --zone europe-west1-c \
  --release-channel stable \
  --enable-ip-alias

kubectl config rename-context gke_big-rob_europe-west1-c_gke-eu gke-eu 

# Create US Cluster
echo "🇺🇸 Create a GKE cluster in the US called gke-us ..."
gcloud container clusters create gke-us \
  --zone us-central1-a \
  --release-channel stable \
  --enable-ip-alias

kubectl config rename-context gke_big-rob_us-central1-a_gke-us gke-us

# Create EU Cluster
echo "🇬🇧 Create a GKE cluster in the UK called gke-uk ..."
gcloud container clusters create gke-uk \
  --zone europe-west2-c \
  --release-channel stable \
  --enable-ip-alias 

kubectl config rename-context gke_big-rob_europe-west2-c_gke-uk gke-uk 

# Create a static IP address to use for the LB
echo "🖥️ Creating a static IP for the loadbalancer so that we can confiure a DNS entry"
gcloud compute addresses create mci-static --global
export MCI_IP=$(gcloud compute addresses describe mci-static --global --format="json" | jq -r .address) 
# gcloud compute addresses describe mci-static --global --format="json"
echo "The IP address created for this is ${MCI_IP}" 

# Register clusters to environ
echo "📒 Register clusters with Anthos Connect"

# gcloud container clusters list --uri

gcloud container hub memberships register gke-eu \
    --project=${project-id} \
    --gke-uri=https://container.googleapis.com/v1/projects/${PROJECT_ID}/zones/europe-west1-c/clusters/gke-eu \
    --service-account-key-file=${SA_KEY_FILE}

gcloud container hub memberships register gke-us \
    --project=${project-id} \
    --gke-uri=https://container.googleapis.com/v1/projects/${PROJECT_ID}/zones/us-central1-a/clusters/gke-us \
    --service-account-key-file=${SA_KEY_FILE}

gcloud container hub memberships register gke-uk \
    --project=${project-id} \
    --gke-uri=https://container.googleapis.com/v1/projects/${PROJECT_ID}/zones/europe-west2-c/clusters/gke-uk \
    --service-account-key-file=${SA_KEY_FILE}

# gcloud container hub memberships list