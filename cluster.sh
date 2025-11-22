#!/bin/bash
set -euo pipefail

CLUSTER_NAME="otus-project"
ZONE="ru-central1-a"
FOLDER_ID=""
NETWORK_ID=""
SUBNET_ID=""
SERVICE_ACCOUNT_ID=""
NODE_SERVICE_ACCOUNT_ID=""
RELEASE_CHANNEL="regular"
RETRY_SLEEP_SECONDS=30
NG_NAME1="infra"
NG_NAME2="payload"
NG1_FIXED_SIZE=2
NG2_FIXED_SIZE=2
NG_CORES=2
NG_MEMORY=4
NG_DISK_SIZE=60
NG_DISK_TYPE="network-hdd"
NG_LABEL1="node-role=infra"
NG_TAINT1="node-role=infra:NoSchedule"

echo "Checking yc.."
if command -v yc >/dev/null 2>&1; then
    echo "yc found!"
else
    echo "ERROR: yc CLI not found..Run 'curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash'" >&2
    exit 1
fi

echo "Checking kubectl.."
if command -v kubectl >/dev/null 2>&1; then
    echo "Kubectl found!"
else
    sudo apt install curl -y >/dev/null 2>&1 
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    echo "Kubectl installed!"
fi

echo "Checking helm.."
if command -v helm >/dev/null 2>&1; then
    echo "Helm found!"
else
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
    bash ./get_helm.sh
    echo "Helm installed!"
fi

echo "Creating managed-kubernetes cluster: ${CLUSTER_NAME} in zone ${ZONE}"
CLUSTER_ID=$(yc managed-kubernetes cluster create \
    --name "${CLUSTER_NAME}" \
    --zone "${ZONE}" \
    --folder-id "${FOLDER_ID}" \
    --network-id "${NETWORK_ID}" \
    --subnet-id "${SUBNET_ID}" \
    --service-account-id "${SERVICE_ACCOUNT_ID}" \
    --node-service-account-id "${NODE_SERVICE_ACCOUNT_ID}" \
    --public-ip \
    --release-channel "${RELEASE_CHANNEL}" \
    --format json | jq -r '.id')

echo "Cluster created!"
echo "${CLUSTER_ID}"

echo "Waiting ${RETRY_SLEEP_SECONDS}s before creating node groups (cluster may be provisioning).."
sleep "${RETRY_SLEEP_SECONDS}"

echo "Creating node-group '${NG_NAME1}'.."
yc managed-kubernetes node-group create "${NG_NAME1}" \
    --cluster-id "${CLUSTER_ID}" \
    --location "zone=${ZONE}" \
    --network-interface "subnets=${SUBNET_ID},ipv4-address=nat" \
    --fixed-size "${NG1_FIXED_SIZE}" \
    --cores "${NG_CORES}" \
    --memory "${NG_MEMORY}" \
    --disk-size "${NG_DISK_SIZE}" \
    --disk-type "${NG_DISK_TYPE}" \
    --node-labels "${NG_LABEL1}" \
    --node-taints "${NG_TAINT1}" \
    --format json

echo "Creating node-group '${NG_NAME2}'.."
yc managed-kubernetes node-group create "${NG_NAME2}" \
    --cluster-id "${CLUSTER_ID}" \
    --location "zone=${ZONE}" \
    --network-interface "subnets=${SUBNET_ID},ipv4-address=nat" \
    --fixed-size "${NG2_FIXED_SIZE}" \
    --cores "${NG_CORES}" \
    --memory "${NG_MEMORY}" \
    --disk-size "${NG_DISK_SIZE}" \
    --disk-type "${NG_DISK_TYPE}" \
    --format json
echo "Node-groups created!"

echo "Fetching kubeconfig for cluster.."
yc managed-kubernetes cluster get-credentials "${CLUSTER_ID}" --external --force
echo "Ready!"
