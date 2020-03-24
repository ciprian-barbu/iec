#!/bin/bash
# shellcheck disable=SC2016

set -ex

basepath=$(cd "$(dirname "$0")"; pwd)

# Using opencord automation-tools from the cord-6.1 maintenance branch
AUTO_TOOLS_GIT="https://github.com/opencord/automation-tools.git"
AUTO_TOOLS_VER=${AUTO_TOOLS_VER:-cord-7.0-arm64}

export M=/tmp/milestones
export SEBAVALUE=
export WORKSPACE=${HOME}

rm -rf "${M}"
mkdir -p "${M}" "${WORKSPACE}/cord/test"

# Update helm-charts submdule needed later
# ignore subproject commit and use latest remote version
git submodule update --init --remote "${basepath}/../../src_repo/helm-charts"

cd "${WORKSPACE}"
test -d automation-tools || git clone "${AUTO_TOOLS_GIT}"
(cd "${WORKSPACE}/automation-tools" && git checkout "${AUTO_TOOLS_VER}")

# Faking helm-charts repo clone to our own git submodule if not already there
CHARTS="${WORKSPACE}/cord/helm-charts"
test -d "${CHARTS}" || test -L "${CHARTS}" || \
    ln -s "${basepath}/../../src_repo/helm-charts" "${CHARTS}"

cd "${WORKSPACE}/automation-tools/seba-in-a-box"
. env.sh

# Now calling make, to install PONSim
make stable

