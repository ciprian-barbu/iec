#!/bin/bash
# shellcheck disable=SC2016

set -ex

basepath=$(cd "$(dirname "$0")"; pwd)

# Using opencord automation-tools from the cord-6.1 maintenance branch
AUTO_TOOLS_GIT="https://github.com/opencord/automation-tools.git"
AUTO_TOOLS_VER=${AUTO_TOOLS_VER:-cord-6.1}

source ${basepath}/../util.sh

export M=/tmp/milestones
export SEBAVALUE=
export WORKSPACE=${HOME}

mkdir -p ${M}
mkdir -p "${WORKSPACE}/cord/test"
# Update helm-charts submdule needed later
git submodule update --init ${basepath}/../../src_repo/helm-charts

cd "${WORKSPACE}"
test -d automation-tools || git clone "${AUTO_TOOLS_GIT}"
cd "${WORKSPACE}/automation-tools" && git checkout "${AUTO_TOOLS_VER}"

# Fake the setup phase so that portcheck.sh is not called
# also install some required packages
sudo apt install -y httpie jq software-properties-common bridge-utils make
touch "${M}/setup"

# Skip helm installation if it already exists and fake /usr/local/bin/helm
if xhelm=$(which helm)
then
  if [ "${xhelm}" != "/usr/local/bin/helm" ]
  then
     echo "helm is installed at ${xhelm}; symlinking to /usr/local/bin/helm"
     mkdir -p /usr/local/bin/ || true
     sudo ln -s "${xhelm}" /usr/local/bin/helm
  fi
else
  echo "helm is not installed"
fi

# Faking helm-charts repo clone to our own git submodule
CHARTS="${WORKSPACE}/cord/helm-charts"
test -h "${CHARTS}" || ln -s "${basepath}/../../src_repo/helm-charts" "${CHARTS}"

# Fake SiaB components setup since they are already installed
milestones="kubeadm helm-init kafka kafka-running etcd-operator-ready voltha \
            voltha-running nem onos siab"

for m in ${milestones}
do
  echo "Faking SiaB milestone ${M}/${m}"
  test -f "${M}/${m}" || touch "${M}/${m}"
done

# Now calling make, to install PONSim
cd "${WORKSPACE}/automation-tools/seba-in-a-box"
make stable

