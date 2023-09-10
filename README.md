# Istio Multi-Cluster Quick Start Guide

If you're new to Istio multi-cluster deployments, this guide is tailored for you. It offers a streamlined step-by-step process to get you up and running quickly.

For a comprehensive understanding, this guide provides detailed instructions to set up Istio in a multi-cluster (Multi-primary) environment and deploy a sample application across the clusters.

NOTE: (This guide assumes you are on macOS or linux system, however all the commands should work, except for the istio installation on your system (Step 1). Please modify the commands as per convenience for this step)

## Step 1: Install `istioctl`

### Download Istio and Install `istioctl`

Begin by downloading the Istio release for your platform and install the `istioctl` command-line tool.

```bash
wget -c "https://github.com/istio/istio/releases/download/1.18.2/istio-1.18.2-osx-arm64.tar.gz" -O istio.tar.gz
tar -xvzf istio.tar.gz
sudo mv -f istio-1.18.2/bin/istioctl /usr/local/bin
```

## Step 2: Generate Certificates

### Generate Necessary Certificates
Execute the script to generate the required certificates. These certificates are crucial for secure communication within the Istio service mesh.
```bash
./generate-certs/generate-certs.sh 2
```

## Step 3: Get GKE Credentials

### Retrieve Google Kubernetes Engine (GKE) Credentials

Obtain the credentials for both clusters to enable kubectl commands to interact with the respective clusters.

```bash
# For Cluster 1
gcloud container clusters get-credentials cluster-1 --zone us-central1-c --project istiosetup
export CLUSTER_1=$(kubectl config current-context)

# For Cluster 2
gcloud container clusters get-credentials cluster-2 --zone us-east1-b --project istiosetup
export CLUSTER_2=$(kubectl config current-context)
```

## Step 4: Install Helm

### Install Helm Package Manager
Helm is a package manager for Kubernetes that simplifies the deployment and management of applications. Install it using the following command:
```bash
brew install helm
```

## Step 5: Install Istio

### Deploy Istio on Both Clusters
Run the script to install Istio on both clusters. Istio will be the service mesh that facilitates secure communication between services.
```bash
./install-istio/install.sh 2
```

## Step 6: Verify Certificates

### Ensure Certificates for Istio Installation
It's crucial to verify that the certificates used for Istio installation are valid and set up correctly. This step ensures secure communication within the Istio mesh.

```bash
./install-istio/verify-cluster-ca-certs.sh 2
```

## Step 7: Generate Client and Server Certificates, Deploy Sample App

### Generate Certificates and Deploy Sample Application
Generate the client and server certificates needed for secure communication and deploy a sample application within the Istio mesh.

```bash
./app-tls/tls.sh 2
```

## Step 8: Determine Ingress IP and Ports

### Obtain Ingress Details for Both Clusters
Determine the details needed to access services through the Ingress. These values will be used in subsequent steps.
```bash
export INGRESS_NAME=istio-ingress
export INGRESS_NS=istio-ingress

# For Cluster 1
export INGRESS_HOST_1=$(kubectl --context=${CLUSTER_1} -n "$INGRESS_NS" get service "$INGRESS_NAME" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export SECURE_INGRESS_PORT_1=$(kubectl --context=${CLUSTER_1} -n "$INGRESS_NS" get service "$INGRESS_NAME" \
    -o jsonpath='{.spec.ports[?(@.name=="https")].port}')

# For Cluster 2
export INGRESS_HOST_2=$(kubectl --context=${CLUSTER_2} -n "$INGRESS_NS" get service "$INGRESS_NAME" \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export SECURE_INGRESS_PORT_2=$(kubectl --context=${CLUSTER_2} -n "$INGRESS_NS" get service "$INGRESS_NAME" \
    -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
```

## Step 9: Make CURL Requests to Deployed Apps

### Interact with Deployed Applications
Execute CURL requests to interact with the deployed applications. These commands allow you to test the deployed services.
```bash
# For Cluster 1
curl -v -HHost:helloworld.example.com \
    --resolve "helloworld.example.com:$SECURE_INGRESS_PORT_1:$INGRESS_HOST_1" \
  --cacert app-tls/example_certs/cluster-1/example.com.crt \
  --cert app-tls/example_certs/cluster-1/client.example.com.crt \
  --key app-tls/example_certs/cluster-1/client.example.com.key \
  "https://helloworld.example.com:$SECURE_INGRESS_PORT_1/hello"

# For Cluster 2
curl -v -HHost:helloworld.example.com \
    --resolve "helloworld.example.com:$SECURE_INGRESS_PORT_2:$INGRESS_HOST_2" \
  --cacert app-tls/example_certs/cluster-2/example.com.crt \
  --cert app-tls/example_certs/cluster-2/client.example.com.crt \
  --key app-tls/example_certs/cluster-2/client.example.com.key \
  "https://helloworld.example.com:$SECURE_INGRESS_PORT_2/hello"

```

These steps will successfully set up Istio in a multi-cluster configuration and deploy a sample application. The provided CURL commands allow you to interact with the deployed applications.