# Cloud Run

![]()
![](https://www.youtube.com/watch?v=gx8VTa1c8DA&autoplay=1)

## What is it


### Features
* Any language, any ibrary, any binary
* Leverage Container workflows and standards
* Enhanced Dev UX
* Fully Managed
* Fast Autoscaling
* Redundancy
* Integrated Logging and Monitoring
* Prcess Web traffic or aysnc events
* Strict Container isolation
* Build on Knative
* HTTPs URL's
* Custom Domains
* gRPC and HTTP/1

## Why use it


## Show me the magic

### Sensible things to have set before starting

Managed Cloud Run
```bash
# Pick the settings that make sense to you!
gcloud config set run/platform managed
gcloud config set run/region europe-west1
gcloud auth configure-docker
gcloud components install docker-credential-gcr
```


Cloud Run for Anthos

```bash
gcloud config set run/platform gke
gcloud config set run/cluster CLUSTER
gcloud config set run/cluster_location ZONE
gcloud container clusters get-credentials CLUSTER
```

If you want to do this this Cloud Run for Anthos a few more steps will be required [here](https://cloud.google.com/run/docs/gke/setup)

### Go

1) Lets get the application you have been working on.

Java Demo (yu might want to follow the [optimisation tips](https://cloud.google.com/run/docs/tips/java));

```bash
git clone git@github.com:clijockey/demo-java-app.git

```

2) You now need to have your application containerised, if you havnt done this you can follow instructions for the demo apps.

Java - 3 options, Dockerfile, [Jib](https://github.com/clijockey/demo-java-app/blob/master/jib.md) or [Buildpacks](https://github.com/clijockey/demo-java-app/blob/master/buildpacks.md)

NOTE: Make sure you have a container that has `latest` tag otherwise you will have to pass the tag with the conatiner img.

3) Deploy the application

If you prefer the UI make use of the [documentation](https://cloud.google.com/run/docs/quickstarts/prebuilt-deploy).

Please note that 2 variations of Cloud Run exist;
* Managed
* Cloud Run for Anthos

```bash
gcloud run deploy --image gcr.io/${PROJECT-ID}/${CONTAINER-IMG} --platform managed
```

EXAMPLE OUTPUT;
```
gcloud run deploy --image eu.gcr.io/clijockey/demo-java-app --platform managed                                                                                  
Service name (demo-java-app):  
Allow unauthenticated invocations to [demo-java-app] (y/N)?  y

Deploying container to Cloud Run service [demo-java-app] in project [clijockey] region [europe-west1]
✓ Deploying new service... Done.                                                             
  ✓ Creating Revision...
  ✓ Routing traffic...                
  ✓ Setting IAM Policy...
Done.                                                                                                                                                                 
Service [demo-java-app] revision [demo-java-app-00001-pih] has been deployed and is serving 100 percent of traffic at https://demo-java-app-p6nxx7ovoq-ew.a.run.app

```

You will notice that a URL (with HTTPS cert) is created and also all traffic is directed to that URL.

4) Access the site and browse around options

The 1st time you browse to the URL it will cause a container to be created (Cloud Run scales down to 0).

`gcloud run services list`
`gcloud run services describe SERVICE`
`gcloud run services describe SERVICE --format yaml`

Have a look around the console to view Metrics/logging/audit/error reporting etc.


5) I have a new feture, how to I roll out?

```bash
gcloud run deploy SERVICE --image gcr.io/PROJECT-ID/IMAGE
```

OUTPUT:
```
Service name (demo-java-app):  
Deploying container to Cloud Run service [demo-java-app] in project [clijockey] region [europe-west1]
✓ Deploying... Done.                                                                                       
  ✓ Creating Revision...
  ✓ Routing traffic...  
Done.                                                                                                      
Service [demo-java-app] revision [demo-java-app-00002-big] has been deployed and is serving 100 percent of traffic at https://demo-java-app-p6nxx7ovoq-ew.a.run.app
```

You will see a revision is created and all traffic is directed to that new container.

Damn! That wasnt right, how do I rollback?

```bash
gcloud run revisions list
gcloud run services update-traffic SERVICE --to-revisions REVISION=100
```

```bash
gcloud run revisions list --service SERVICE
```
Should now show that you have moved all traffic back to the revison you require.

Now I have fixed by bug and also learnt from my big bang approach ....

```bash
gcloud run deploy --image gcr.io/PROJECT-ID/IMAGE --no-traffic
```

You can test the new version before ever letting user see it and then start to intorduce (blue/green)

```bash
gcloud run revisions list
gcloud run services update-traffic SERVICE --to-revisions REVISION=10
```
OUTPUT;
```
gcloud run services update-traffic demo-java-app --to-revisions demo-java-app-00004-fef=10    
✓ Updating traffic... Done.                                                                                
  ✓ Routing traffic...
Done.                                                                                                      
Traffic: https://demo-java-app-p6nxx7ovoq-ew.a.run.app
  90% demo-java-app-00001-pih
  10% demo-java-app-00004-fef
```

Now im happy just direct all user traffic to the latest version;

```bash 
gcloud run services update-traffic SERVICE --to-latest
```

[OPTIONAL]
What about directing traffic to 3 different versions?

```bash
gcloud run services update-traffic SERVICE --to-revisions REVISION1=10,REVISION2=30,REVISON3=70
```


6) I saw something called Buildpacks above - can they make the containerisation stage easier?




7) Lets create a pipeline

8) Autoscale
<Way to generate load for scale to kick in>
https://github.com/rakyll/hey

9) Connect GCP services

https://cloud.google.com/run/docs/using-gcp-services

10) I dont want to use `gcloud` help!

You have a few ways to deploy workloads to Cloud Run;
* GCP Console - If you like GUI
* `gcloud` - if you are happy with this CLI
* YAML - I want to keep close to OSS
* Terraform - I usually work with TF

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: SERVICE
spec:
  template:
    spec:
      containers:
      - image: IMAGE
```

Ok so still kind of end up using `gcloud` however you have greater control on the Knative manifest definitions.
```bash
gcloud beta run services replace service.yaml
```


```json
provider "google" {
    project = "PROJECT-ID"
}

resource "google_cloud_run_service" "default" {
    name     = "SERVICE"
    location = "REGION"

    metadata {
      annotations = {
        "run.googleapis.com/client-name" = "terraform"
      }
    }

    template {
      spec {
        containers {
          image = "gcr.io/PROJECT-ID/IMAGE"
        }
      }
    }
 }

 data "google_iam_policy" "noauth" {
   binding {
     role = "roles/run.invoker"
     members = ["allUsers"]
   }
 }

 resource "google_cloud_run_service_iam_policy" "noauth" {
   location    = google_cloud_run_service.default.location
   project     = google_cloud_run_service.default.project
   service     = google_cloud_run_service.default.name

   policy_data = data.google_iam_policy.noauth.policy_data
}
```

```bash
terraform init
terraform apply
```

11) What about multi-region?

https://cloud.google.com/run/docs/multiple-regions

## Other Resources

A number of use-cases are documented on the [GCP documentation](https://cloud.google.com/run);
* Website
* Rest API's Backend
* Back Office Admin
* Data processing: Lightweight data transformation
* Automation: Scheduled document generation
* Automation: Business workflow with webhooks

A numbmer of [tutorials](https://cloud.google.com/run/docs/tutorials) also exist on the GCP site.
