#!/bin/bash

# This script performs maintenance on Dockerfile repositories. It ensures git submodules are
# installed and then copies over base files from the modules. It also generates the
# documentation and performs other miscellaneous tasks.

set -ex

if [ ! -d "./.modules/shared" ]; then
  mkdir -p ./.modules
  git submodule add -b master https://gitlab.com/megabyte-space/common/shared.git ./.modules/shared
else
  cd ./.modules/shared
  git checkout master && git pull origin master
  cd ../..
fi
pwd
source "../shared/update.lib.sh"

ensure_node_installed
ensure_jq_installed
ensure_dockerslim_installed
ensure_docker_pushrm_installed

add_initctl

ensure_project_docs_submodule_latest

# Copy over files from the shared submodule
cp -Rf ./.modules/shared/.github .
cp -Rf ./.modules/shared/.gitlab .
cp -Rf ./.modules/shared/.vscode .
cp ./.modules/shared/.editorconfig .editorconfig
cp ./.modules/shared/CODE_OF_CONDUCT.md CODE_OF_CONDUCT.md

copy_project_files_and_generate_package_json
generate_documentation

misc_fixes
