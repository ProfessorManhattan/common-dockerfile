#!/bin/bash

# This script performs maintenance on Dockerfile repositories. It ensures git submodules are
# installed and then copies over base files from the modules. It also generates the
# documentation and performs other miscellaneous tasks.

set -e

# Ensure shared submodule is present
if [ ! -d "./.modules/shared" ]; then
  mkdir -p ./.modules
  git submodule add -b master https://gitlab.com/megabyte-space/common/shared.git ./.modules/shared
else
  cd ./.modules/shared
  git checkout master && git pull origin master
  cd ../..
fi

source "./.modules/shared/update.lib.sh"

# Install software dependencies if they are missing
ensure_node_installed
ensure_jq_installed
ensure_dockerslim_installed
ensure_docker_pushrm_installed

# Ensure initctl file is present in root, if required
add_initctl

# Ensure documentation partials submodule is present and in sync with master
ensure_project_docs_submodule_latest

# Copy over files from the shared submodule
cp -Rf ./.modules/shared/.github .
cp -Rf ./.modules/shared/.gitlab .
cp -Rf ./.modules/shared/.vscode .
cp ./.modules/shared/.editorconfig .editorconfig
cp ./.modules/shared/CODE_OF_CONDUCT.md CODE_OF_CONDUCT.md

# Apply updates from shared files
copy_project_files_and_generate_package_json
generate_documentation
misc_fixes
update_docker_labels
