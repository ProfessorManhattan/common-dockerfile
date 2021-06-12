#!/bin/bash

# This file tests the latest and slim build and then compares
# their outputs to ensure they are the same. It does this for each
# folder located in the test folder.

# shellcheck disable=SC1091
source "./.modules/shared/update.lib.sh"

if [[ "$(docker images -q megabytelabs/DOCKER_SLUG:slim 2>/dev/null)" == "" ]] || [[ "$(docker images -q megabytelabs/DOCKER_SLUG:latest 2>/dev/null)" == "" ]]; then
  info "The images have not been built yet"
  log "Running 'npm run build'"
  npm run build
  success "Finished building the images"
fi

for TEST_SCENARIO in test/*/; do
  log "Running the regular image and capturing the output for the ${TEST_SCENARIO} scenario"
  LATEST_OUTPUT=$(docker run -v "${PWD}/${TEST_SCENARIO}:/work" -w /work megabytelabs/DOCKER_SLUG:latest DOCKER_COMMAND)
  log "Running the slim image and capturing the output for the ${TEST_SCENARIO} scenario"
  SLIM_OUTPUT=$(docker run -v "${PWD}/${TEST_SCENARIO}:/work" -w /work megabytelabs/DOCKER_SLUG:slim DOCKER_COMMAND)
  log "Comparing the output from the regular image and slim image for the ${TEST_SCENARIO} scenario"
  if [ "$LATEST_OUTPUT" == "$SLIM_OUTPUT" ]; then
    success "The output from the slim image matches the output from the regular image for the ${TEST_SCENARIO} scenario"
  else
    error "The output from the slim image does not match the output from the regular image for the ${TEST_SCENARIO} scenario"
    exit 1
  fi
done
