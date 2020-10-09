# Buildpacks 


## Install and set-up

* Have an app you want to containerise ready - this repo has a Java example
* Install `pack`
* If you want to remove all the docker images from your machine 
```bash
docker rmi -f $(docker images -a -q)
```
* `pack set-default-builder gcr.io/buildpacks/builder:v1`
* Environment varaibales listed in `.envrc-example`  


## To the demo

### Developer Hat

I have finished writing/adding to my app and now I want to create a container. We will use Cloud Native buildpacks, which makes use of a CLI tool called `pack`.

Lets just run it locally to check everything is as expected - `./mvnw -DskipTests spring-boot:run` (yes I am a bad human for skipping tests)

```bash
pack build eu.gcr.io/$PROJECT_ID/coffee:v1
```

This will now create the container image.

In the detection phase, we see that the builder automatically detects which buildpacks to use:

```bash
# OUTPUT WILL BE SOMETHING LIKE THIS
v1: Pulling from buildpacks/builder
Digest: sha256:61d53c4f75f79f158ea68d5d44d628acf3c6e2582b517f8968a3c4b5ce3ca8a6
Status: Image is up to date for gcr.io/buildpacks/builder:v1
v1: Pulling from buildpacks/gcp/run
Digest: sha256:ce9cc3addebd6bcb63690138bcdccfdebeeaf733aa950c722c34755fe0f47b74
Status: Image is up to date for gcr.io/buildpacks/gcp/run:v1
===> DETECTING
4 of 5 buildpacks participating
google.java.runtime    0.9.0
google.java.maven      0.9.0
google.java.entrypoint 0.9.0
google.utils.label     0.0.1
===> ANALYZING
Previous image with name "eu.gcr.io/clijockey/coffee:v1" not found
===> RESTORING
===> BUILDING
=== Java - Runtime (google.java.runtime@0.9.0) ===
Using latest Java 11 runtime version. You can specify a different version with GOOGLE_RUNTIME_VERSION: https://github.com/GoogleCloudPlatform/buildpacks#configuration
--------------------------------------------------------------------------------
Running "curl --silent https://api.adoptopenjdk.net/v3/assets/feature_releases/11/ga?architecture=x64&heap_size=normal&image_type=jdk&jvm_impl=hotspot&os=linux&page=0&page_size=1&project=jdk&sort_order=DESC&vendor=adoptopenjdk"

[
    {
        "binaries": [
            {
                "architecture": "x64",
                "download_count": 145617,
                "heap_size": "normal",
                "image_type": "jdk",
                "jvm_impl": "hotspot",
                "os": "linux",
                "package": {
                    "checksum": "6e4cead158037cb7747ca47416474d4f408c9126be5b96f9befd532e0a762b47",
                    "checksum_link": "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz.sha256.txt",
                    "download_count": 145617,
                    "link": "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz",
                    "metadata_link": "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz.json",
                    "name": "OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz",
                    "size": 193398310
                },
                "project": "jdk",
                "scm_ref": "jdk-11.0.8+10_adopt",
                "updated_at": "2020-07-15T14:30:29Z"
            }
        ],
        "download_count": 706177,
        "id": "MDc6UmVsZWFzZTI4NTg5Nzcz.pCNBA7G9E1o7pw==",
        "release_link": "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/tag/jdk-11.0.8%2B10",
        "release_name": "jdk-11.0.8+10",
        "release_type": "ga",
        "timestamp": "2020-07-15T14:29:27Z",
        "updated_at": "2020-07-15T14:29:27Z",
        "vendor": "adoptopenjdk",
        "version_data": {
            "build": 10,
            "major": 11,
            "minor": 0,
            "openjdk_version": "11.0.8+10",
            "security": 8,
            "semver": "11.0.8+10"
        }
    }
]Done "curl --silent https://api.adoptopenjdk.net/v3/assets/feature..." (974.69067ms)
Installing Java v11.0.8+10
--------------------------------------------------------------------------------
Running "bash -c curl --fail --show-error --silent --location --retry 3 https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz | tar xz --directory /layers/google.java.runtime/java --strip-components=1"
Done "bash -c curl --fail --show-error --silent --location --retry..." (38.167505827s)
=== Java - Maven (google.java.maven@0.9.0) ===
--------------------------------------------------------------------------------
Running "./mvnw clean package --batch-mode -DskipTests --quiet"
Done "./mvnw clean package --batch-mode -DskipTests --quiet" (1m4.02398963s)
=== Java - Entrypoint (google.java.entrypoint@0.9.0) ===
=== Utils - Label Image (google.utils.label@0.0.1) ===
===> EXPORTING
Adding layer 'google.java.runtime:java'
Adding 1/1 app layer(s)
Adding layer 'launcher'
Adding layer 'config'
Adding label 'io.buildpacks.lifecycle.metadata'
Adding label 'io.buildpacks.build.metadata'
Adding label 'io.buildpacks.project.metadata'
*** Images (a022e574d577):
      eu.gcr.io/clijockey/coffee:v1
Adding cache layer 'google.java.runtime:java'
Adding cache layer 'google.java.maven:m2'
Successfully built image eu.gcr.io/clijockey/coffee:v1

```


```bash
docker images
```

```
docker run -p 8080:8080 eu.gcr.io/$PROJECT_ID/coffee:v1
```
```bash
dive eu.gcr.io/$PROJECT_ID/coffee:v1
```

Lets make some changes to the app, and this time we will also publish the container image to the registry.

```bash
# Alter the application
pack build --publish eu.gcr.io/$PROJECT_ID/coffee:v2
```

You should notice the build is a bit faster;
* The builder and run (stack) images are now available in the local Docker repository
* Even though we made a change to our app code, the build was able to re-use layers from the app image and from cache (pay special attention to the logs for the restoring, analyzing, and exporting phases). Building a layered image enables pack to efficiently recreate only the layers that have changed.

Notice the reusing layers, time to build etc...

```bash
# OUTPUT
v1: Pulling from buildpacks/builder
Digest: sha256:61d53c4f75f79f158ea68d5d44d628acf3c6e2582b517f8968a3c4b5ce3ca8a6
Status: Image is up to date for gcr.io/buildpacks/builder:v1
v1: Pulling from buildpacks/gcp/run
Digest: sha256:ce9cc3addebd6bcb63690138bcdccfdebeeaf733aa950c722c34755fe0f47b74
Status: Image is up to date for gcr.io/buildpacks/gcp/run:v1
===> DETECTING
4 of 5 buildpacks participating
google.java.runtime    0.9.0
google.java.maven      0.9.0
google.java.entrypoint 0.9.0
google.utils.label     0.0.1
===> ANALYZING
Restoring metadata for "google.java.runtime:java" from app image
Restoring metadata for "google.java.maven:m2" from cache
===> RESTORING
Restoring data for "google.java.runtime:java" from cache
Restoring data for "google.java.maven:m2" from cache
===> BUILDING
=== Java - Runtime (google.java.runtime@0.9.0) ===
Using latest Java 11 runtime version. You can specify a different version with GOOGLE_RUNTIME_VERSION: https://github.com/GoogleCloudPlatform/buildpacks#configuration
--------------------------------------------------------------------------------
Running "curl --silent https://api.adoptopenjdk.net/v3/assets/feature_releases/11/ga?architecture=x64&heap_size=normal&image_type=jdk&jvm_impl=hotspot&os=linux&page=0&page_size=1&project=jdk&sort_order=DESC&vendor=adoptopenjdk"

[
    {
        "binaries": [
            {
                "architecture": "x64",
                "download_count": 145617,
                "heap_size": "normal",
                "image_type": "jdk",
                "jvm_impl": "hotspot",
                "os": "linux",
                "package": {
                    "checksum": "6e4cead158037cb7747ca47416474d4f408c9126be5b96f9befd532e0a762b47",
                    "checksum_link": "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz.sha256.txt",
                    "download_count": 145617,
                    "link": "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz",
                    "metadata_link": "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz.json",
                    "name": "OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz",
                    "size": 193398310
                },
                "project": "jdk",
                "scm_ref": "jdk-11.0.8+10_adopt",
                "updated_at": "2020-07-15T14:30:29Z"
            }
        ],
        "download_count": 706177,
        "id": "MDc6UmVsZWFzZTI4NTg5Nzcz.pCNBA7G9E1o7pw==",
        "release_link": "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/tag/jdk-11.0.8%2B10",
        "release_name": "jdk-11.0.8+10",
        "release_type": "ga",
        "timestamp": "2020-07-15T14:29:27Z",
        "updated_at": "2020-07-15T14:29:27Z",
        "vendor": "adoptopenjdk",
        "version_data": {
            "build": 10,
            "major": 11,
            "minor": 0,
            "openjdk_version": "11.0.8+10",
            "security": 8,
            "semver": "11.0.8+10"
        }
    }
]Done "curl --silent https://api.adoptopenjdk.net/v3/assets/feature..." (801.041574ms)
=== Java - Maven (google.java.maven@0.9.0) ===
--------------------------------------------------------------------------------
Running "./mvnw clean package --batch-mode -DskipTests --quiet"
Done "./mvnw clean package --batch-mode -DskipTests --quiet" (38.884720051s)
=== Java - Entrypoint (google.java.entrypoint@0.9.0) ===
=== Utils - Label Image (google.utils.label@0.0.1) ===
===> EXPORTING
Reusing layer 'google.java.runtime:java'
Adding 1/1 app layer(s)
Reusing layer 'launcher'
Adding layer 'config'
Adding label 'io.buildpacks.lifecycle.metadata'
Adding label 'io.buildpacks.build.metadata'
Adding label 'io.buildpacks.project.metadata'
*** Images (c3b45a640714):
      eu.gcr.io/clijockey/coffee:v2
Reusing cache layer 'google.java.runtime:java'
Reusing cache layer 'google.java.maven:m2'
Successfully built image eu.gcr.io/clijockey/coffee:v2

```

```bash
dive eu.gcr.io/$PROJECT_ID/coffee:v2
```

Lets say I needed to control the JVM version, this is possible with envvars, in this case you can pass `GOOGLE_RUNTIME_VERSION`. More exist in the documentation - this build will fail becuase the app is designed for Java 11! 

```bash
pack build --publish eu.gcr.io/$PROJECT_ID/coffee:v8 --env GOOGLE_RUNTIME_VERSION="8"
```

```bash
#cloud build
```



### Operations View

Great, the devs are happy but whats in it for the ops folks?

pack provides a way to inspect our app image;

```bash
pack inspect-image eu.gcr.io/$PROJECT_ID/coffee:v2 
```

```bash
#OUTPUT
Inspecting image: eu.gcr.io/clijockey/coffee:v2

REMOTE:
(not present)

LOCAL:

Stack: google

Base Image:
  Reference: 64b0eb7764de6dbabd4cd5eae74b32bff502fc5c73c5f63fd2e765a24c808ec4
  Top Layer: sha256:a32133ac24cdf5636d4391071824aaa53d7eac8aac5e94aba71a803b74027453

Run Images:
  gcr.io/buildpacks/gcp/run:v1

Buildpacks:
  ID                            VERSION
  google.java.runtime           0.9.0
  google.java.maven             0.9.0
  google.java.entrypoint        0.9.0
  google.utils.label            0.0.1

Processes:
  TYPE                 SHELL        COMMAND        ARGS
  web (default)                     java           -jar /workspace/target/demo-0.0.1-SNAPSHOT.jar


```

A bill of materials also exists to help with audit.

```
pack inspect-image eu.gcr.io/$PROJECT_ID/coffee:v2 --bom | jq .
```

Since buildpacks are modular and pluggable, we can contribute our own custom buildpacks to the build or use another one that exists. 

Lets create the image with a different builder and see what that looks like;

```bash
pack suggest-builders
pack inspect-builder gcr.io/buildpacks/builder:v1
pack inspect-builder gcr.io/paketo-buildpacks/builder:full-cf
```
Great, lets build using a different builder

```bash
pack build eu.gcr.io/$PROJECT_ID/coffee:cf --builder gcr.io/paketo-buildpacks/builder:full-cf
```
```bash
docker images
dive eu.gcr.io/$PROJECT_ID/coffee:cf
pack inspect-image eu.gcr.io/$PROJECT_ID/coffee:cf
pack inspect-image eu.gcr.io/$PROJECT_ID/coffee:cf --bom | jq .
```

You can alter the default builders with  `pack set-default-builder gcr.io/buildpacks/builder:v1`

#### Rebase is WIP

```bash
# Change layer/rebase

pack rebase eu.gcr.io/$PROJECT_ID/coffee:v3 --run-image gcr.io/buildpacks/gcp/run:504104bbd82cffb03454f9527bd20bf1a72ce852
pack inspect-image eu.gcr.io/$PROJECT_ID/coffee:v3
dive eu.gcr.io/$PROJECT_ID/coffee:v3
```

```bash
#pack build eu.gcr.io/$PROJECT_ID/coffee:v3 --builder gcr.io/buildpacks/builder:775ac8cb2b824aca86f96604f8f8345fb1568cfd
```

```bash
#pack rebase eu.gcr.io/$PROJECT_ID/coffee:v3 --run-image gcr.io/buildpacks/gcp/run:latest  
#pack rebase eu.gcr.io/$PROJECT_ID/coffee:v3 --run-image gcr.io/buildpacks/gcp/
```

### Serverless and Cloud Run

What about creating a Cloud Function
```bash
pack build fn-coffee --builder gcr.io/buildpacks/builder:v1 --env GOOGLE_FUNCTION_TARGET=myFunction
```
You can also use Cloud Run to be triggered on git changes and make use of buildpacks to automatically create image and deploy - https://cloud.google.com/run/docs/continuous-deployment-with-cloud-build