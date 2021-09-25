#!/bin/bash

set -xe

# Maybe start emulator
emu_pattern='java .* /opt/google-cloud-sdk/platform/cloud-datastore-emulator/'
emu_started_by_us=

if ! pgrep -lf "${pattern}"; then
    gcloud beta emulators datastore start &
    emu_started_by_us=true
fi

# Following comes from `gcloud beta emulators datastore env-init'
export DATASTORE_DATASET=id-me-helloworld
export DATASTORE_EMULATOR_HOST=localhost:8081
export DATASTORE_EMULATOR_HOST_PATH=localhost:8081/datastore
export DATASTORE_HOST=http://localhost:8081
export DATASTORE_PROJECT_ID=id-me-helloworld

# Start container with environment
# (also use host-network so we can get to loopback on host)
docker run --rm -it \
       -v "$PWD":/usr/src/app \
       -w /usr/src/app \
       -e DATASTORE_DATASET \
       -e DATASTORE_EMULATOR_HOST \
       -e DATASTORE_EMULATOR_HOST_PATH \
       -e DATASTORE_HOST \
       -e DATASTORE_PROJECT_ID \
       --network=host \
       ruby:2.5-slim bash \

# Maybe stop emulator
if [ -n "$emu_started_by_us" ]; then
    pkill -f "${pattern}"
fi
