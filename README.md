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
Emulator](https://cloud.google.com/datastore/docs/tools/datastore-emulator); see
the [`./utils/`](./utils/) directory.

# Production considerations

A few brief ideas pertaining to real-world applications:
[./docs/FUTURE.md](./docs/FUTURE.md)
