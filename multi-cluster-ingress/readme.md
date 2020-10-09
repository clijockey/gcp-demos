# Multi-Cluster Ingress

-----------------------------------------
NOTE: Need to dry run this from scratch!!
-----------------------------------------

## Setup [OPTIONAL]
Create the GKE cluststers to use as part of the demo. If you dont already have clusters spun up the `setup.sh` script will spin up 3 clusters, one in the US, one in the EU and one in the UK. The manual steps can be followed in the (documentation)[https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-for-anthos-setup] along with the requirements.

Prereq;
* `gcloud` installed and logged
* envvar set that are in `envrc-example`, you will need to specify your project name. If you use (direnv[https://direnv.net/]) just remain to `.envrc`.

Run;
```bash
./setup.sh
```

The script has also created a static IP that will be used for the load balancer anycast address, it is stored in the envvar `$MCI_IP`

## Demo

You will need to decide which of you clusters will act ast the "Config Cluster".

The config cluster is a GKE cluster you choose to be the central point of control for Ingress across the member clusters. Unlike GKE Ingress, the Anthos Ingress controller does not live in a single cluster but is a Google-managed service that watches resources in the config cluster. This GKE cluster is used as a multi-cluster API server to store resources such as `MultiClusterIngress` and `MultiClusterService`. Any member cluster can become a config cluster, but there can only be one config cluster at a time.

For more information about config clusters, see (Config cluster design)[https://cloud.google.com/kubernetes-engine/docs/concepts/ingress-for-anthos#config_cluster_design].

Check that the clusters you want to include are registered;

```bash
gcloud container hub memberships list
```

Now enable Ingress for Anthos, I have picked the UK cluster.

```bash
gcloud alpha container hub ingress enable \
  --config-membership=projects/${PROJECT_ID}/locations/global/memberships/gke-uk
```

Now check the progress and feature state;

```bash
gcloud alpha container hub ingress describe
```

Great now the feature is enabled lets make a delpoyment. Firstly you will need to create the `namespace` and `deployment` acorss the 3 clusters (you could have this setup via ACM). To simply this a script has been created (if you prefer just apply both `namespace.yaml` and `deploy.yaml`);

```bash
./config_ns.sh
```

Now time to deploy the MCI configuration, make sure you have the correct context set (`kubectl config use-context gke-uk`) for the "Config Cluster".

We will now deploy the `MultiClusterIngress` (MCI) and `MutiClusterService` (MCS) resources. These are CRD's that are multi-cluster equivalents of `ingress` and `service` resources. 

First lets start with the MCS.

```yaml
# mcs.yaml
apiVersion: networking.gke.io/v1
kind: MultiClusterService
metadata:
  name: zone-mcs
  namespace: zoneprinter
spec:
  template:
    spec:
      selector:
        app: zoneprinter
      ports:
      - name: web
        protocol: TCP
        port: 8080
        targetPort: 8080
```

```bash
kubectl apply -f mcs.yaml
```

```bash
kubectl get mcs -n zoneprinter
```

This MCS creates a derived headless Service in every cluster that matches Pods with `app: zoneprinter`. You can see that one exists in the gke-uk cluster 

```
kubectl get service -n zoneprinter
```

A similar headless Service will also exist in gke-eu & gke-us. These local Services are used to dynamically select Pod endpoints to program the global Ingress load balancer with backends.


Now create the ingress.

```yaml
# mci.yaml
apiVersion: networking.gke.io/v1
kind: MultiClusterIngress
metadata:
  name: zone-ingress
  namespace: zoneprinter
spec:
  template:
    spec:
      backend:
        serviceName: zone-mcs
        servicePort: 8080
```

Note that this configuration routes all traffic to the `MultiClusterService` named `zone-mcs` that exists in the `zoneprinter` namespace.

[OPTIONAL] If you want to use the file downloaded from this repo you will need to alter the static IP address. If you followed the earlier setup instructions you should have an envvar `$MCI_IP` which you create the `mci.yaml` file;

```
envsubst < mci-var.yaml > mci.yaml 
```

```
kubectl apply -f mci.yaml
```
Note that `MultiClusterIngress` has the same schema as the Kubernetes Ingress. The Ingress resource semantics are also the same with the exception of the `backend.serviceName` field.

The `backend.serviceName` field in a `MultiClusterIngress` references a `MultiClusterService` in the Hub API rather than a Service in a Kubernetes cluster. This means that any of the settings for Ingress, such as TLS termination, settings can be configured in the same way.

### Validation

A Cloud Load Balancer should now start to be created, this can take several minutes to fully deploy. Updating exitsing load balancers completes faster. 

Verify the deployment has finshed;

```
kubectl describe mci zone-ingress -n zoneprinter
```

Once it is you will see the `ingress vip` displayed in the `VIP` field.

`curl <ingress vip>/ping` or just browse to `http://<ingress vip>` . The cluster that the traffic is forwarded to depends on location. The GCLB is designed to forward client traffic to the closest available backend with capacity.

The following shows the relationship between MCI/MCS and the load balancers across 2 member clusters.
!()[https://cloud.google.com/kubernetes-engine/images/mci-mcs-gce-load-balancer.png]

Some commands to try;
```
kubectl describe mcs zone-svc
kubectl describe mci zone-ingress
```

TODO: ssl cert
TODO: setup with DNS against VIP
TODO: narative to the demo

# Clean up

```
./cleanup_ns.sh
```