#!/bin/bash

set -ex

CORD_REPO="${CORD_REPO:-https://github.com/iecedge/cord-tester.git}"
CORD_REV="cord-7.0-arm64"
VOLTHA_REPO="${VOLTHA_REPO:-https://github.com/opencord/voltha.git}"
VOLTHA_REV="master"
K8S_MASTER_IP="${K8S_MASTER_IP:-127.0.0.1}"
KUBE_DIR="${KUBE_DIR:-/workspace/.kube}"
USER="${USER:-ubuntu}"

# The ssh server must be running since cord-tester tries to connect
# to localhost
sudo apt-get update
sudo apt-get install httpie -y
sudo apt-get install jq -y
sudo /etc/init.d/ssh restart
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa 2>/dev/null <<< y >/dev/null
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
cd "${HOME}"
sudo cp -r "${KUBE_DIR}" .kube
sudo chown -R "$(id -u)":"$(id -g)" .kube

git clone "${CORD_REPO}" cord-tester -b "${CORD_REV}"
git clone "${VOLTHA_REPO}" voltha -b "${VOLTHA_REV}"

cd cord-tester/
make venv_cord
pwd
# shellcheck disable=SC1091
source venv_cord/bin/activate
cd src/test/cord-api
# As per documentation, we set the SERVER_IP before anything
sed -i "s/SERVER_IP.*=.*'/SERVER_IP = '${K8S_MASTER_IP}'/g" \
     Properties/RestApiProperties.py
cd Tests/WorkflowValidations/

export SERVER_IP="${K8S_MASTER_IP}"

TESTTAGS="stable"
PYBOT_ARGS="-v SUBSCRIBER_FILENAME:SIABSubscriberLatest -v WHITELIST_FILENAME:SIABWhitelistLatest -v OLT_DEVICE_FILENAME:SIABOLT0Device"
robot ${PYBOT_ARGS} --removekeywords wuks -e notready -i ${TESTTAGS} -v VOLTHA_DIR:${HOME}/voltha SIAB.robot

