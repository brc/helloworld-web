# HelloWorld web app

This is the web application component of the HelloWorld service. It is a Ruby program which uses [Sinatra](http://sinatrarb.com/) to expose URL paths.

## Code

HelloWorld-web is a monolithic procedural script which combines all concerns
and is difficult to test! Refactoring for a real design would be fairly trivial.

When the root `/` URL is requested, GCP Firestore is queried for a known
[entity](https://cloud.google.com/datastore/docs/concepts/entities) and the
message contained therein is simply returned to the caller. Firestore for this
project is configured in ["Datastore
mode"](https://cloud.google.com/datastore/docs/concepts/overview).

## Packaging

Gem dependencies and versions are captured with [Bundler](https://bundler.io/),
which are then frozen under the official
[`ruby:2.5-slim`](https://hub.docker.com/layers/ruby/library/ruby/2.5-slim/images/sha256-94808dd25d747505dc45cb2e0227159bfeec3c48c2eab45c4306bc82e40d731c?context=explore)
Docker image.

## Deployment

HelloWorld-web is currently deployed to GCP [Cloud
Run](https://cloud.google.com/run) in two US regions (east and west), as
controlled by the [`cloudbuild.yaml`](./cloudbuild.yaml) file in this repo
(more below under the [**CI/CD**](#cicd) section).

These services are configured to be accessible _internally_ only (*i.e.*, NOT by
the public Internet), but are pool members of an external HTTPS (L7) load
balancer.

## Performance

The L7 load balancer contains a global Google anycast address on the front-end
which will route end-users to the region nearest them. New regions can be added
to `cloudbuild.yaml` and provisioned very easily as product demand grows.

This web app is not yet optimized for "cold starts," and the
[WEBrick](https://docs.ruby-lang.org/en/2.4.0/WEBrick.html) HTTP server should
be replaced with a more performant web server. However, Cloud Run will scale the
service automatically, increasing the number of replicas horizontally as demand
increases.

Though the Firestore key is indexed, and Firestore in "datastore mode" can scale
to millions of operations per second, a real web application would likely
benefit from a caching tier that sits between it and the database. This may also
reduce cost at scale. See the [Designing for
Scale](https://cloud.google.com/datastore/docs/best-practices#designing_for_scale)
section of Google's "Datastore Best Practices" article for more information
about key distribution, contention (hot spots), latency, and ramp-up.

## Security

A WAF similar to [Cloud Armor](https://cloud.google.com/armor) would be used
in protection to help identify and mitigate DDoS attacks, etc.

### GCP Authentication

Authentication logic for Firestore is not handled by this application because
the default IAM policies used by the Cloud Run Service Agent allow various
traffic and permissions within the same GCP Project.

### IAM Policies

In a real application environment, more granular IAM policies would be crafted
and bound to dedicated Service Accounts, yielding a "least privilege" model for
services which provision and consume other services and resources.

## Pricing

There was not time to conduct forecasting or major comparison for various
architectures as they relate to operational expenditure (OpEx), though the
author is highly aware of these considerations at scale.

For example, when does [GKE](https://cloud.google.com/kubernetes-engine) become
cheaper than Cloud Run (or vice versa)? What about storage systems? Egress
transit? Sustained-use and/or committment discounts? etc. Many organizations
form Center Of Excellence (COE) teams who become experts in optimizing cloud
spend.


# CI/CD

[Cloud Build](https://cloud.google.com/build/) is used to build and deploy this
application via [Build
Triggers](https://cloud.google.com/build/docs/automating-builds/create-manage-triggers)
for this GitHub repo.

Pull requests from approved collaboraters will automatically build a new Docker
image and push it to the `docker-dev`
[Artifact](https://cloud.google.com/artifact-registry) repo in the separate
`id-me-build` project with an image tag corresponding to the pull-request number
(*e.g.*, `helloworld:23`). This image will then be deployed to a new Cloud Run
service named `helloworld-dev-pr23`, in a single region.

> **NOTE:** Cloud Run services deployed for PRs are currently not added to a dev load balancer pool. In a real project, the test service would be added behind an LB so that E2E testing and UAT could commence appropriately.

When pull requests are merged, the *same* image built from the PR will be
promoted to the `docker-release` repo (hence, the image is never rebuilt after
being tested) and the image will be deployed to multiple regions for the Cloud
Run services named `helloworld-prod`, which sit behind the production HTTPS LB.

# Hacking locally

Development of this application can occur locally by using the GCP SDK
[Datastore
Emulator](https://cloud.google.com/datastore/docs/tools/datastore-emulator):

```
$ gcloud beta emulators datastore start
```

A container can then be launched in the Docker host network to access `localhost`:

```bash
# populate environment
$ `gcloud beta emulators datastore env-init`

# launch container
$ docker run --rm -it \
       -v "$PWD":/usr/src/app \
       -w /usr/src/app \
       -e DATASTORE_DATASET \
       -e DATASTORE_EMULATOR_HOST \
       -e DATASTORE_EMULATOR_HOST_PATH \
       -e DATASTORE_HOST \
       -e DATASTORE_PROJECT_ID \
       --network=host \
       ruby:2.5-slim bash

root@fe92e3030524:/usr/src/app# bundle install
```

In a real project, there would be tooling to help achieve a nice workflow (such
as populating the emulated database with test data).
