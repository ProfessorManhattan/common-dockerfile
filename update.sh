#!/bin/bash

# This script performs maintenance on this repository. It ensures git submodules are
# installed and then copies over base files from the modules. It also generates the
# documentation.

set -ex

# Determine type of Dockerfile project
DOCKERFILE_PROJECT_TYPE=$(cat .blueprint.json | jq '.subgroup' | cut -d '"' -f 2)
if [ "$DOCKERFILE_PROJECT_TYPE" == "ansible-molecule" ]; then
  # Run logic unique to the container's OS
  DOCKERFILE_FIRSTLINE=$(head -n 1 ./Dockerfile)
  if [[ "$DOCKERFILE_FIRSTLINE" == *"ubuntu"* ]]; then
    cp ./.modules/dockerfile/initctl initctl
  fi
  if [[ "$DOCKERFILE_FIRSTLINE" == *"debian"* ]]; then
    cp ./.modules/dockerfile/initctl initctl
  fi
fi

# Ensure submodules are present and up-to-date
if [ ! -d "./.modules/docs" ]; then
  git submodule add -b master https://gitlab.com/megabyte-space/documentation/dockerfile.git ./.modules/docs
else
  cd ./.modules/docs
  git checkout master && git pull origin master
  cd ../..
fi
if [ ! -d "./.modules/shared" ]; then
  git submodule add -b master https://gitlab.com/megabyte-space/common/shared.git ./.modules/shared
else
  cd ./.modules/shared
  git checkout master && git pull origin master
  cd ../..
fi

# Copy over files from the shared submodule
cp -Rf ./.modules/shared/.github .
cp -Rf ./.modules/shared/.gitlab .
cp -Rf ./.modules/shared/.vscode .
cp ./.modules/shared/.editorconfig .editorconfig
cp ./.modules/shared/CODE_OF_CONDUCT.md CODE_OF_CONDUCT.md

# Copy files over from the Dockerfile shared submodule
if [ -f ./package.json ]; then
  # Retain information from package.json
  PACKAGE_NAME=$(cat package.json | jq '.name' | cut -d '"' -f 2)
  PACKAGE_VERSION=$(cat package.json | jq '.version' | cut -d '"' -f 2)
  if [ "$DOCKERFILE_PROJECT_TYPE" == "ansible-molecule" ]; then
    PACKAGE_DESCRIPTION=$(cat package.json | jq '.description' | cut -d '"' -f 2)
  fi
  cp -Rf ./.modules/dockerfile/files/ .
  jq --arg a "${PACKAGE_NAME}" '.name = $a' package.json > __jq.json && mv __jq.json package.json
  jq --arg a "${PACKAGE_VERSION//\/}" '.version = $a' package.json > __jq.json && mv __jq.json package.json
  if [ "$DOCKERFILE_PROJECT_TYPE" == "ansible-molecule" ]; then
    jq --arg a "${PACKAGE_DESCRIPTION//\/}" '.description = $a' package.json > __jq.json && mv __jq.json package.json
  fi
  npx prettier-package-json --write
else
  cp -Rf ./.modules/dockerfile/files/ .
  BLUEPRINT_PACKAGE_NAME=$(cat .blueprint.json | jq '.slug' | cut -d '"' -f 2)
  jq --arg a "${BLUEPRINT_PACKAGE_NAME}" '.name = $a' package.json > __jq.json && mv __jq.json package.json
  npx prettier-package-json --write
fi

# Ensure the pre-commit hook is executable
chmod 755 .husky/pre-commit

# Update references to project name in package.json
PACKAGE_NAME=$(cat package.json | jq '.name' | cut -d '"' -f 2)
sed -i .bak "s^dockerfile-project^${PACKAGE_NAME}^g" package.json
rm package.json.bak | true

# Update DockerSlim command
PACKAGE_DOCKER_COMMAND=$(cat .blueprint.json | jq '.dockerslim_command' | cut -d '"' -f 2)
sed -i .bak "s^DOCKER_SLIM_COMMAND_HERE^${PACKAGE_DOCKER_COMMAND}^g" package.json
rm package.json.bak | true

# Handle Dockerfile project-type specific README.md template reference
BLUEPRINT_README_FILE="blueprint-readme.md"
if [ "$DOCKERFILE_PROJECT_TYPE" == "ansible-molecule" ]; then
  BLUEPRINT_README_FILE="blueprint-readme-ansible-molecule.md"
elif [ "$DOCKERFILE_PROJECT_TYPE" == "ci-pipeline" ]; then
  BLUEPRINT_README_FILE="blueprint-readme-ci.md"
  # Build the images if slim.report.json is not present
  if [ ! -f ./slim.report.json ]; then
    npm run build
  fi
  # Inject the image size into the description
  BLUEPRINT_PACKAGE_DESCRIPTION=$(cat .blueprint.json | jq '.description_template' | cut -d '"' -f 2)
  SLIM_IMAGE_SIZE=$(cat slim.report.json | jq '.minified_image_size_human' | cut -d '"' -f 2)
  jq --arg a "${BLUEPRINT_PACKAGE_DESCRIPTION}" '.description = $a' package.json > __jq.json && mv __jq.json package.json
  sed -i .bak "s^SLIM_IMAGE_SIZE^${SLIM_IMAGE_SIZE}^g" package.json
  rm package.json.bak | true
  npx prettier-package-json --write
elif [ "$DOCKERFILE_PROJECT_TYPE" == "apps" ]; then
  BLUEPRINT_README_FILE="blueprint-readme-apps.md"
elif [ "$DOCKERFILE_PROJECT_TYPE" == "software" ]; then
  BLUEPRINT_README_FILE="blueprint-readme-software.md"
fi

# Generate the documentation
jq -s '.[0] * .[1]' .blueprint.json ./.modules/docs/common.json > __bp.json | true
npx -y @appnest/readme generate --config __bp.json --input ./.modules/docs/blueprint-contributing.md --output CONTRIBUTING.md | true
npx -y @appnest/readme generate --config __bp.json --input ./.modules/docs/$BLUEPRINT_README_FILE | true
rm __bp.json

# Inject DockerSlim build command into README.md
if [ "$DOCKERFILE_PROJECT_TYPE" == "ci-pipeline" ]; then
  PACKAGE_SLIM_BUILD=$(cat package.json | jq '.scripts."build:slim"' | cut -d '"' -f 2)
  sed -i '.bak' "s^DOCKER_SLIM_BUILD_COMMAND^${PACKAGE_SLIM_BUILD}^g" README.md
fi

# Remove formatting error
sed -i .bak 's/](#-/](#/g' README.md
rm README.md.bak | true
sed -i .bak 's/](#-/](#/g' CONTRIBUTING.md
rm CONTRIBUTING.md.bak | true

# Ensure .blueprint.json is formatted properly
npx prettier --write .blueprint.json

# Ensure slim.report.json is properly formatted
npx prettier --write slim.report.json

# Ensure docker-pushrm plugin is installed to user's ~/.docker folder
if [ "$(uname)" == "Darwin" ]; then
    DOCKER_PUSHRM_DOWNLOAD_LINK=https://github.com/christian-korneck/docker-pushrm/releases/download/v1.7.0/docker-pushrm_darwin_amd64
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    DOCKER_PUSHRM_DOWNLOAD_LINK=https://github.com/christian-korneck/docker-pushrm/releases/download/v1.7.0/docker-pushrm_linux_amd64
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    # Do something under 32 bits Windows NT platform
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    # Do something under 64 bits Windows NT platform
fi
# TODO: Support Windows as well
if [ ! -f $HOME/.docker/cli-plugins/docker-pushrm ]; then
  mkdir -p $HOME/.docker/cli-plugins
  wget $DOCKER_PUSHRM_DOWNLOAD_LINK -O $HOME/.docker/cli-plugins/docker-pushrm
  chmod +x $HOME/.docker/cli-plugins/docker-pushrm
fi

echo "*** Done updating meta files and generating documentation ***"
