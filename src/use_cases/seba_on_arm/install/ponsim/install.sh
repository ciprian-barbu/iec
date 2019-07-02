#!/bin/bash -ex
# shellcheck disable=SC2016

basepath=$(cd "$(dirname "$0")"; pwd)

# Using opencord automation-tools from the cord-6.1 maintenance branch
AUTO_TOOLS_VER=${AUTO_TOOLS_VER:-cord-6.1}

source ${basepath}/../util.sh

export M=/tmp/milestones
export SEBAVALUE=
export WORKSPACE={HOME}

mkdir -p ${M}
mkdir -p {$WORKSPACE}/cord/test

cd ${WORKSPACE} && git clone https://github.com/opencord/automation-tools.git
cd ${WORKSPACE}/automation-tools && git checkout ${AUTO_TOOLS_VER}

# Fake the setup phase so that portcheck.sh is not called
# also install some required packages
touch ${M}/setup
apt install -y httpie jq software-properties-common

# prepare helm-charts repo

milestones="kubeadm helm-init"
