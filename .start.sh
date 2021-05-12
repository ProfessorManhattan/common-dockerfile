#!/bin/bash

# This script performs maintenance on this repository. It ensures git submodules are
# installed and then copies over base files from the modules. It also generates the
# documentation.

set -e

if [ "$container" != 'docker' ]; then
  curl -sL https://git.io/_has | bash -s docker git jq node npm wget
fi

export REPO_TYPE=dockerfile
git submodule update --init --recursive
if [ ! -f "./.modules/${REPO_TYPE}/update.sh" ]; then
  mkdir -p ./.modules || exit
  git submodule add -b master --depth 1 https://gitlab.com/megabyte-space/common/$REPO_TYPE.git ./.modules/$REPO_TYPE
else
  cd ./.modules/$REPO_TYPE || exit
  git config pull.rebase true
  git checkout master
  git pull --depth 1 --allow-unrelated-histories --rebase origin master
  cd ../.. || exit
fi
bash ./.modules/$REPO_TYPE/update.sh
