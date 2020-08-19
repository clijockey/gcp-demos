
go/sme-lab-3
go/sme-lab-4
go/sme-lab-5

`pack --h


What's a builder, anyway?
A builder is an image that bundles all the bits and information on how to build your apps. 
     * includes the buildpacks that will be used as well as the environment for building and running your app. 
     * The builder we specified is publicly available on Docker Hub cloudfoundry/cnb (click on the Tags tab to see available builder images).

We can use pack to get more information about the builder:
     pack suggest-builders

     pack inspect-builder gcr.io/buildpacks/builder:v1

          From the output, you can see that this builder supports several programming frameworks through ordered sets of modular buildpacks, and it specifies the order of detection that will be applied to applications. You can also see the stack and the run image that the builder will use for the app image it produces.

     pack inspect-builder gcr.io/paketo-buildpacks/builder:full-cf 

     docker images

     pack build coffee:gcp --builder gcr.io/buildpacks/builder:v1
     gcr.io/paketo-buildpacks/builder:full-cf 

     docker images
          You should see both the builder image as well as the run image. pack downloaded both of these during the first build. We can expect future builds with the same builder to be faster as they can use the local copies.

     pack inspect-image coffee:gcp

     docker run -p 8080:8080 coffee:gcp

     pack inspect-image coffee:gcp

     pack set-default-builder gcr.io/buildpacks/builder:v1

Change some code;
     pack build coffee:gcp2

     pack build --publish gcr.io/big-rob/coffee:v2

     pack build fn-coffee --builder gcr.io/buildpacks/builder:v1 --env GOOGLE_FUNCTION_TARGET=myFunction


     pack build coffee:rebase --builder gcr.io/buildpacks/builder:775ac8cb2b824aca86f96604f8f8345fb1568cfd

     pack rebase coffee:rebase --run-image gcr.io/buildpacks/gcp/run:latest  
     pack rebase coffee:rebase --run-image gcr.io/buildpacks/gcp/run@sha256:838856abec8d7d2178cfc13d3f598bb6ea51a9abc23784e3ee22a01d0966e32d  



40 years old!!!! docker images hahaha

pack inspect-image rob:v2 --bom
pack inspect-image rob:v2 --bom | jq .remote
pack inspect-image coffee:rebase
pack rebase coffee:rebase --run-image gcr.io/buildpacks/gcp/run:504104bbd82cffb03454f9527bd20bf1a72ce852
pack inspect-image rob:rebase

docker push gcr.io/big-rob/rob:rebase
-----------------------


In the detection phase, we see that the builder automatically detects which buildpacks to use:

===> DETECTING
[detector] 7 of 13 buildpacks participating
[detector] org.cloudfoundry.openjdk                   v1.2.11
...
In the analysis & restore phases, it finds opportunities for optimization and for restoring from cache. Since this is the first time we are using the specified builder and building this image, there are none:

===> ANALYZING
[analyzer] Warning: Image "index.docker.io/library/spring-sample-app:latest" not found
===> RESTORING
In the build phase, it applies the participating buildpacks that it detected earlier, in order. Notice that each contributes to the app image in layers, including the JDK (to compile from source), the JRE (for the runtime image), the Build System (for the Maven build), etc...

===> BUILDING
[builder]
[builder] Cloud Foundry OpenJDK Buildpack v1.2.11
[builder]   OpenJDK JDK 11.0.6: Contributing to layer
...
[builder]   OpenJDK JRE 11.0.6: Contributing to layer
...
[builder] Cloud Foundry Build System Buildpack v1.2.9
[builder]     Using wrapper
[builder]     Linking Cache to /home/cnb/.m2
[builder]   Compiled Application (133 files): Contributing to layer
...
[builder] [INFO] Replacing main artifact with repackaged archive
[builder] [INFO] ------------------------------------------------------------------------
[builder] [INFO] BUILD SUCCESS
[builder] [INFO] ------------------------------------------------------------------------
...
[builder] Cloud Foundry JVM Application Buildpack v1.1.9
[builder]   Executable JAR: Contributing to layer
In the export phase, it produces the layered OCI image for our application. Layering will make it more efficient to update in the future. The image name is the name we specified in our pack build command; the tag is latest since we didn't specify a tag.

===> EXPORTING
[exporter] Adding layer 'launcher'
...
[exporter] Adding layer 'org.cloudfoundry.openjdk:openjdk-jre'
[exporter] Adding layer 'org.cloudfoundry.openjdk:security-provider-configurer'
...
[exporter] *** Images (c38380737b91):
[exporter]       index.docker.io/library/spring-sample-app:latest
The export phase also caches layers, enabling more efficient re-builds in the future.

[exporter] Adding cache layer 'org.cloudfoundry.openjdk:openjdk-jdk'
[exporter] Adding cache layer 'org.cloudfoundry.buildsystem:build-system-application'
...
Wait until the command completes. You should see Successfully built image spring-sample-app as the last line in the log.


Let's dive further into the pack build command by re-building the image and examining the log again.

Before we re-build, let's make a small code change.

App source code change
Recall that the app displayed the message "hello, world". Let's change that for our next build.

Run the following commands to cd into the app directory and update the source code:

cd ~/spring-sample-app
sed -i 's/hello/greetings/g' src/main/java/com/example/springsampleapp/HelloController.java
You can verify that the file contains the updated string using cat src/main/java/com/example/springsampleapp/HelloController.java

Re-build the image
Now, let's re-build the image. We no longer need to specify the builder since we have set a default builder. We also no longer need to specify the path since we are now in the directory containing the source code. Hence, we can run a simplified pack build command with only the image name:

pack build spring-sample-app
Speedy re-build
Notice that the build is faster the second time. A few factors contribute to this:

The builder and run (stack) images are now available in the local Docker repository

Spring/Java dependencies are now available in a local Maven (.m2) repository

Even though we made a change to our app code, the build was able to re-use layers from the app image and from cache (pay special attention to the logs for the restoring, analyzing, and exporting phases). Building a layered image enables pack to efficiently recreate only the layers that have changed.

Validate that the image was updated (the image id has changed):

docker images | grep spring-sample-app
Re-run the app to see the updated message:

docker run -it -p 8080:8080 spring-sample-app
Send a request to the app:

curl localhost:8080; echo
Send Ctrl+C to stop the app before proceeding to the next step.

Inspect & customize the image
pack provides a way to inspect our app image:

pack inspect-image spring-sample-app
You can see the run image and the buildpacks used to create the app image. What if you want to influence the build by adding a few instructions? One option is to add a custom buildpack.

Add a custom buildpack
Since buildpacks are modular and pluggable, we can contribute our own custom buildpacks to the build. You can read more about creating custom buildpacks here later, but for now, let's use a simple example custom buildpack. This buildpack just prints some lines to the log during the build, but you could create a custom buildpack that does anything that makes sense for your organization or your application.

To run the sample buildpack, you could list each buildpack that you see in the output of the inspect-image command in your pack build command, in order, and include your custom buildpack in the list. Alternatively, you can use the shorthand from=builder, as shown below, to cause the custom buildpack to run before or after the buildpacks from the builder.

Re-run the pack build command as shown below to run the custom buildpack after the builder buildpacks have run:

pack build spring-sample-app \
     --buildpack from=builder \
     --buildpack ~/samples/buildpacks/hello-world
Find the log entries showing the custom buildpack was executed, starting with:

[builder] ---> Hello World buildpack
Look through the rest of the log and notice that the existing layers and cache, which were not altered by the addition of the custom buildpack, were re-used.

You can also inspect the image again to validate the additional buildpack was used.

pack inspect-image spring-sample-app
Diving deeper: rebasing, publishing, setting env vars, and more...
To learn more about other cool features like re-basing, publishing to a remote docker registry, setting build-time environment variables, and more, please refer to the documentation and git repo.

For now, complete the other scenarios in this course to explore alternate platforms for using buildpacks to translate source code to images.
