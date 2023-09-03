#!/bin/bash

export TOTAL_CLUSTERS=$1

for ((CLUSTER_INDEX=1;CLUSTER_INDEX<=${TOTAL_CLUSTERS};CLUSTER_INDEX++)); do
    export CLUSTER_INDEX
    export CONTEXT_INDEX=CLUSTER_${CLUSTER_INDEX}
    CONTEXT="$(eval echo \$$CONTEXT_INDEX)"
    CLUSTER_NAME=cluster-${CLUSTER_INDEX}
    # Deploy the helloworld and sleep sample services
    kubectl --context="$CONTEXT" create ns sample
    kubectl --context="$CONTEXT" label namespace sample istio-injection=enabled
    sleep 1; kubectl --context=${CONTEXT} delete -f ~/istio-1.18.2/samples/helloworld/helloworld.yaml -l service=helloworld -n sample
    sleep 1; kubectl --context=${CONTEXT} delete -f ~/istio-1.18.2/samples/helloworld/helloworld.yaml -l version=v1 -n sample
    sleep 1; kubectl --context=${CONTEXT} apply -f ~/istio-1.18.2/samples/helloworld/helloworld.yaml -l service=helloworld -n sample
    sleep 2; kubectl --context=${CONTEXT} apply -f ~/istio-1.18.2/samples/helloworld/helloworld.yaml -l version=v1 -n sample
    #### Generate client and server certificates and keys ####
    mkdir -p app-tls/example_certs/${CLUSTER_NAME}
    openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' \
        -keyout app-tls/example_certs/${CLUSTER_NAME}/example.com.key \
        -out app-tls/example_certs/${CLUSTER_NAME}/example.com.crt
        # Generate a certificate and a private key for helloworld.example.com
    openssl req -out app-tls/example_certs/${CLUSTER_NAME}/helloworld.example.com.csr -newkey rsa:2048 -nodes \
        -keyout app-tls/example_certs/${CLUSTER_NAME}/helloworld.example.com.key \
        -subj "/CN=helloworld.example.com/O=helloworld organization"
    openssl x509 -req -sha256 -days 365 -CA app-tls/example_certs/${CLUSTER_NAME}/example.com.crt \
        -CAkey app-tls/example_certs/${CLUSTER_NAME}/example.com.key -set_serial 1 \
        -in app-tls/example_certs/${CLUSTER_NAME}/helloworld.example.com.csr \
        -out app-tls/example_certs/${CLUSTER_NAME}/helloworld.example.com.crt
        # Generate a client certificate and private key:
    openssl req -out app-tls/example_certs/${CLUSTER_NAME}/client.example.com.csr -newkey rsa:2048 -nodes \
        -keyout app-tls/example_certs/${CLUSTER_NAME}/client.example.com.key \
        -subj "/CN=client.example.com/O=client organization"
    openssl x509 -req -sha256 -days 365 -CA app-tls/example_certs/${CLUSTER_NAME}/example.com.crt \
        -CAkey app-tls/example_certs/${CLUSTER_NAME}/example.com.key -set_serial 1 \
        -in app-tls/example_certs/${CLUSTER_NAME}/client.example.com.csr \
        -out app-tls/example_certs/${CLUSTER_NAME}/client.example.com.crt
        # Create a secret for the ingress gateway:
    kubectl --context=${CONTEXT} -n istio-ingress delete secret helloworld-credential
    kubectl --context=${CONTEXT} create -n istio-ingress secret generic helloworld-credential \
        --from-file=tls.key=app-tls/example_certs/${CLUSTER_NAME}/helloworld.example.com.key \
        --from-file=tls.crt=app-tls/example_certs/${CLUSTER_NAME}/helloworld.example.com.crt \
        --from-file=ca.crt=app-tls/example_certs/${CLUSTER_NAME}/example.com.crt
    kubectl --context=${CONTEXT} apply -f app-tls/manifests
done