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

## Step 2: Create a Service Account in Your GCP Project

1. Navigate to the [Google Cloud Console](https://console.cloud.google.com/).
2. Select your project and go to the IAM & Admin > Service accounts section.
3. Click on "Create Service Account".
4. Provide a name and description for the service account, then click "Create".
5. In the "Role" section, add the following roles:
   - Kubernetes Engine Cluster Admin
   - Service Account User
   - Storage Object Admin
6. Click "Continue" and then "Done" to complete the creation process.

**Note**: After creating the service account, you'll be able to download a JSON key file. Keep this file secure, as it contains credentials for the service account.

## Storing Service Account JSON File in GitHub Secrets

To use a service account JSON file in your GitHub Actions workflow, you can securely store it in GitHub secrets. Follow these steps:

1. **Navigate to Repository Settings:**

   - Go to your GitHub repository.
   - Click on the "Settings" tab.

2. **Access Secrets:**

   - Scroll down to the "Secrets" section in the left sidebar and click on "Actions".

3. **Add New Repository Secret:**

   - Click on the "New repository secret" button.

4. **Name the Secret:**

   - Give your secret a descriptive name (e.g., `GOOGLE_CREDENTIALS`).

5. **Copy JSON Content:**

   - Open the JSON file of your service account in a text editor.
   - Copy the entire content.

6. **Paste JSON Content:**

   - In the GitHub repository secrets page, paste the JSON content into the "Value" field.

7. **Save the Secret:**

   - Click on "Add secret" to securely store the service account JSON file.

Now, you can refer to this secret in your GitHub Actions workflow YAML file using `secrets.YOUR_SECRET_NAME`. For example, if your secret is named `GOOGLE_CREDENTIALS`, you can use it like this:

```yaml
...
- id: 'auth'
  name: 'Authenticate to Google Cloud'
  uses: 'google-github-actions/auth@v1'
  with:
    credentials_json: '${{ secrets.GOOGLE_CREDENTIALS }}'
...
```
This allows you to securely access your service account credentials in your workflow without exposing them in your code.


## Step 2: Create GKE Clusters

Use the provided GitHub Actions workflow YAML file to automatically create a GKE cluster. 

Make sure to replace the project-id and locations in terraform code as needed

## Step 3: Generate Certificates

### Generate Necessary Certificates
Execute the script to generate the required certificates. These certificates are crucial for secure communication within the Istio service mesh.
```bash
./generate-certs/generate-certs.sh 2
```

## Step 4: Get GKE Credentials

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

## Step 5: Install Helm

### Install Helm Package Manager
Helm is a package manager for Kubernetes that simplifies the deployment and management of applications. Install it using the following command:
```bash
brew install helm
```

## Step 6: Install Istio

### Deploy Istio on Both Clusters
Run the script to install Istio on both clusters. Istio will be the service mesh that facilitates secure communication between services.
```bash
./install-istio/install.sh 2
```

## Step 7: Verify Certificates

### Ensure Certificates for Istio Installation
It's crucial to verify that the certificates used for Istio installation are valid and set up correctly. This step ensures secure communication within the Istio mesh.

```bash
./install-istio/verify-cluster-ca-certs.sh 2
```

## Step 8: Generate Client and Server Certificates, Deploy Sample App

### Generate Certificates and Deploy Sample Application
Generate the client and server certificates needed for secure communication and deploy a sample application within the Istio mesh.

```bash
./app-tls/tls.sh 2
```

## Step 9: Determine Ingress IP and Ports

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

## Step 10: Make CURL Requests to Deployed Apps

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