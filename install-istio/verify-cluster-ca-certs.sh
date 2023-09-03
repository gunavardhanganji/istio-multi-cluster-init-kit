#!/bin/bash

export TOTAL_CLUSTERS=$1

for ((CLUSTER_INDEX=1;CLUSTER_INDEX<=${TOTAL_CLUSTERS};CLUSTER_INDEX++)); do
    export CLUSTER_INDEX
    export CONTEXT_INDEX=CLUSTER_${CLUSTER_INDEX}
    CONTEXT="$(eval echo \$$CONTEXT_INDEX)"
    # Deploy the httpbin and sleep sample services
    sleep 1; kubectl --context="$CONTEXT" create ns foo
    sleep 1; kubectl --context="$CONTEXT" label namespace foo istio-injection=enabled
    sleep 1; kubectl --context="$CONTEXT" apply -f ~/istio-1.18.2/samples/httpbin/httpbin.yaml -n foo
    sleep 1; kubectl --context="$CONTEXT" apply -f ~/istio-1.18.2/samples/sleep/sleep.yaml -n foo
    sleep 1; kubectl --context="$CONTEXT" apply -f install-istio/peer-authentication.yaml -n foo
    # Verifying the certificates
    # we verify that workload certificates are signed by the certificates that we plugged into the CA.
    # This requires you have openssl installed on your machine.
    CLUSTER_NAME=cluster-${CLUSTER_INDEX}
    mkdir -p tmp/${CLUSTER_NAME}
    # Sleep 20 seconds for the mTLS policy to take effect before retrieving the certificate chain of httpbin. 
    # As the CA certificate used in this example is self-signed, the verify error:num=19:self signed certificate 
    # in certificate chain error returned by the openssl command is expected.
    sleep 20; kubectl --context="$CONTEXT" exec \
        "$(kubectl --context="$CONTEXT" get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" \
        -c istio-proxy -n foo -- \
        openssl s_client -showcerts -connect httpbin.foo:8000 > tmp/${CLUSTER_NAME}/httpbin-proxy-cert.txt
    # Parse the certificates on the certificate chain.
    sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' \
        tmp/${CLUSTER_NAME}/httpbin-proxy-cert.txt > tmp/${CLUSTER_NAME}/certs.pem
    sleep 1; awk -v cluster_name=${CLUSTER_NAME} '/-----BEGIN CERTIFICATE-----/ {flag=1; counter++; filename = "tmp/" cluster_name "/proxy-cert-" counter ".pem"; \
        print > filename; next} /-----END CERTIFICATE-----/ {flag=0; print >> filename} \
        flag {print > filename}' \
        < tmp/${CLUSTER_NAME}/certs.pem
    # Verify the root certificate is the same as the one specified by the administrator:
    openssl x509 -in generate-certs/certs/root-cert.pem -text -noout > tmp/${CLUSTER_NAME}/root-cert.crt.txt
    openssl x509 -in tmp/${CLUSTER_NAME}/proxy-cert-3.pem -text -noout > tmp/${CLUSTER_NAME}/pod-root-cert.crt.txt
    diff -q -s ./tmp/${CLUSTER_NAME}/root-cert.crt.txt tmp/${CLUSTER_NAME}/pod-root-cert.crt.txt
    # Verify the CA certificate is the same as the one specified by the administrator:
    openssl x509 -in  generate-certs/certs/${CLUSTER_NAME}/ca-cert.pem -text -noout > tmp/${CLUSTER_NAME}/ca-cert.crt.txt
    openssl x509 -in tmp/${CLUSTER_NAME}/proxy-cert-2.pem -text -noout > tmp/${CLUSTER_NAME}/pod-cert-chain-ca.crt.txt
    diff -q -s tmp/${CLUSTER_NAME}/ca-cert.crt.txt tmp/${CLUSTER_NAME}/pod-cert-chain-ca.crt.txt
    # Verify the certificate chain from the root certificate to the workload certificate:
    openssl verify -CAfile <(cat generate-certs/certs/${CLUSTER_NAME}/ca-cert.pem generate-certs/certs/root-cert.pem) \
        tmp/${CLUSTER_NAME}/proxy-cert-1.pem
done
