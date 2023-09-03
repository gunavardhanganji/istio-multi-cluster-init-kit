#!/bin/bash
set -ex

CERTIFICATES_COUNT=$1

cert_dir="./generate-certs/certs"

echo "Clean up contents of dir './certs'"
rm -rf ${cert_dir}

echo "Generating new certificates"

mkdir ${cert_dir}

# Generate the root certificate and key
cd ${cert_dir}
make -f ~/istio-1.18.2/tools/certs/Makefile.selfsigned.mk root-ca

# For each cluster, generate an intermediate certificate and key for the Istio CA
for ((i=1;i<=${CERTIFICATES_COUNT};i++)); do
    make -f ~/istio-1.18.2/tools/certs/Makefile.selfsigned.mk cluster-${i}-cacerts
done
cd ..