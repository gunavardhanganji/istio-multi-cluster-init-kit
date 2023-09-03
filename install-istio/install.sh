#!/bin/bash

set -xe

export TOTAL_CLUSTERS=$1

export MESH_ID=istio-mesh
export MESH_NETWORK=istio-mesh-network

# Configure the Helm repository
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

mkdir -p tmp

for ((CLUSTER_INDEX=1;CLUSTER_INDEX<=${TOTAL_CLUSTERS};CLUSTER_INDEX++)); do
    export CLUSTER_INDEX
    export CONTEXT_INDEX=CLUSTER_${CLUSTER_INDEX}
    CONTEXT="$(eval echo \$$CONTEXT_INDEX)"
    # In each cluster, create a secret cacerts
    kubectl --context="$CONTEXT" create ns istio-system
    kubectl --context="$CONTEXT" create secret generic cacerts -n istio-system \
        --from-file=./generate-certs/certs/cluster-${CLUSTER_INDEX}/ca-cert.pem \
        --from-file=./generate-certs/certs/cluster-${CLUSTER_INDEX}/ca-key.pem \
        --from-file=./generate-certs/certs/root-cert.pem \
        --from-file=./generate-certs/certs/cluster-${CLUSTER_INDEX}/cert-chain.pem

    # Install the Istio base chart
    helm --kube-context="$CONTEXT" install istio-base istio/base -n istio-system --set defaultRevision=default --wait
    # Install the Istio discovery chart which deploys the istiod service
    export CLUSTER_NAME=cluster-${CLUSTER_INDEX}
    envsubst '$MESH_ID $CLUSTER_NAME $MESH_NETWORK' < install-istio/istiod-values.yaml > install-istio/istiod-values-cluster-${CLUSTER_INDEX}.yaml
    helm --kube-context="$CONTEXT" install -f install-istio/istiod-values-cluster-${CLUSTER_INDEX}.yaml istiod istio/istiod -n istio-system --wait
    # Install an ingress gateway
    kubectl --context="$CONTEXT" create namespace istio-ingress
    helm --kube-context="$CONTEXT" install istio-ingress istio/gateway -n istio-ingress --wait
    
    # Enable Endpoint Discovery
    # Install a remote secret in cluster2 that provides access to cluster1’s API server and vice-versa.
    for ((i=1;i<=${TOTAL_CLUSTERS};i++)); do
        if [ ${i} != ${CLUSTER_INDEX} ]; then
            istioctl --context="$CONTEXT" x create-remote-secret --name="cluster-${i}" > tmp/cluster-secret-${i}.yaml
            kubectl --context="$CONTEXT" apply -f tmp/cluster-secret-${i}.yaml
        fi
    done

done