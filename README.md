## Install istioctl
```
wget -c "https://github.com/istio/istio/releases/download/1.18.2/istio-1.18.2-osx-arm64.tar.gz" -O istio.tar.gz
tar -xvzf istio.tar.gz
sudo mv -f istio-1.18.2/bin/istioctl /usr/local/bin
```

## Generate CERTS
```
./generate-certs/generate-certs.sh 2
```

## GET GKE creds
```
gcloud container clusters get-credentials cluster-1 --zone us-central1-c --project istiosetup
export CLUSTER_1=$(kubectl config current-context)
gcloud container clusters get-credentials cluster-2 --zone us-east1-b --project istiosetup
export CLUSTER_2=$(kubectl config current-context)
```

## Install helm
```
brew install helm
```

# install istio
```
./install-istio/install.sh 2
```

# verify the certs for istio installation
```
./install-istio/verify-cluster-ca-certs.sh 2
```

# Generate client and server certificates and keys and deploy a sample helloworld app
```
./app-tls/tls.sh 2
```
## Determining the ingress IP and ports
```
export INGRESS_NAME=istio-ingress
export INGRESS_NS=istio-ingress
export INGRESS_HOST_1=$(kubectl --context=${CLUSTER_1} -n "$INGRESS_NS" get service "$INGRESS_NAME" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export SECURE_INGRESS_PORT_1=$(kubectl --context=${CLUSTER_1} -n "$INGRESS_NS" get service "$INGRESS_NAME" \
    -o jsonpath='{.spec.ports[?(@.name=="https")].port}')

export INGRESS_HOST_2=$(kubectl --context=${CLUSTER_2} -n "$INGRESS_NS" get service "$INGRESS_NAME" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export SECURE_INGRESS_PORT_2=$(kubectl --context=${CLUSTER_2} -n "$INGRESS_NS" get service "$INGRESS_NAME" \
    -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
```

## Now make the curl request to the deployed apps
```
curl -v -HHost:helloworld.example.com \
    --resolve "helloworld.example.com:$SECURE_INGRESS_PORT_1:$INGRESS_HOST_1" \
  --cacert app-tls/example_certs/cluster-1/example.com.crt \
  --cert app-tls/example_certs/cluster-1/client.example.com.crt \
  --key app-tls/example_certs/cluster-1/client.example.com.key \
  "https://helloworld.example.com:$SECURE_INGRESS_PORT_1/hello"

curl -v -HHost:helloworld.example.com \
    --resolve "helloworld.example.com:$SECURE_INGRESS_PORT_2:$INGRESS_HOST_2" \
  --cacert app-tls/example_certs/cluster-2/example.com.crt \
  --cert app-tls/example_certs/cluster-2/client.example.com.crt \
  --key app-tls/example_certs/cluster-2/client.example.com.key \
  "https://helloworld.example.com:$SECURE_INGRESS_PORT_2/hello"
```