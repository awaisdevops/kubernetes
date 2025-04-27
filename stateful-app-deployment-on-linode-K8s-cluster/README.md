# Stateful App Deployment on Linode K8s Cluster

In this project, we’ll deploy a managed Kubernetes cluster on Linode by setting up a replicated MongoDB database using Helm and StatefulSets, with data persistence configured via Linode’s cloud storage. We’ll then deploy Mongo Express as a browser-accessible UI client and expose it using an NGINX Ingress Controller with proper ingress rules.

This practical setup covers essential Kubernetes concepts—like stateful applications, persistence, and ingress that are applicable across different databases and cloud platforms, helping you build scalable and accessible cloud-native applications efficiently.

---

## Pre-requisites for the Guide

The prerequisites to follow this guide are `kubectl` and `helm`.

### Install `kubectl`

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
kubectl version --client
```

---

### Install `Helm`

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## Create a Kubernetes Cluster via Linode Cloud Manager

1. Go to [https://cloud.linode.com](https://cloud.linode.com) and log in to your Linode account.
2. In the left-hand menu, click "Kubernetes".
3. Click the "Create Cluster" button.
4. Fill out the Cluster Details section:
   - Cluster Label: Enter a unique name (e.g., `my-first-cluster`)
   - Region: Choose a data center location close to your users (e.g., Newark, Frankfurt)
   - Kubernetes Version: Pick the version you want to use
5. Scroll to the Add Node Pools section:
   - Select a plan (e.g., Shared CPU)
   - Choose a plan size (e.g., 2GB Linode)
   - Select the number of nodes (e.g., 3 nodes)
   - Click Add
6. Optionally, add tags
7. Review pricing
8. Click "Create Cluster"
9. Wait a few minutes for provisioning

---

## Access and Configure `kubectl` to Use Your Cluster

1. After the cluster is ready, click into it from the Kubernetes page in the Linode Cloud Manager.
2. Click the "Download Kubeconfig" button.
3. Save the file locally (e.g., `~/lke-kubeconfig.yaml`)
4. In your terminal:

```bash
export KUBECONFIG=~/lke-kubeconfig.yaml
kubectl get nodes
```

You should see a list of nodes with status `Ready`.

---

> We’ll use a Linode managed Kubernetes service called LKE that fully manages the master nodes—including their creation, security, and backups—so you only need to focus on managing the worker nodes.

---

## Deploy MongoDB StatefulSet Using Helm

Create a file named `mongodb-values.yaml` with the following content:

```yaml
architecture: replicaset
replicaCount: 3
persistence:
  storageClass: "linode-block-storage"
auth:
  rootPassword: secret-root-pwd
```

Then run:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
# Adds the Bitnami Helm chart repository

helm repo update
# Updates your local Helm chart repository cache

helm install mongodb --values mongodb-values.yaml bitnami/mongodb
# Installs MongoDB using the Bitnami chart with the release name "my-mongo"

kubectl get pods
# Lists the MongoDB pods to check if they're running

kubectl get statefulsets
# Verifies that MongoDB is deployed as a StatefulSet

kubectl get secret --namespace default mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 --decode
# Retrieves and decodes the MongoDB root password from Kubernetes secrets
```

After deployment, Linode automatically created persistent volumes—one for each pod—using the predefined storage class. These volumes were dynamically provisioned and attached to the nodes where the pods are running.

---

## Deploy Mongo Express

We can create Mongo Express manifests manually as it only requires a deployment and a service component.

### mongo-express-deployment.yaml

```yaml
apiVersion: apps/v1  # Defines the API version of the deployment
kind: Deployment  # Specifies the resource type (Deployment)
metadata:
  name: mongo-express  # Name of the deployment
  labels:
    app: mongo-express  # Label to identify the deployment
spec:
  replicas: 1  # Number of pod replicas
  selector:
    matchLabels:
      app: mongo-express  # Label selector to match the pods
  template:
    metadata:
      labels:
        app: mongo-express  # Labels for the pods created by this deployment
    spec:
      containers:
      - name: mongo-express  # Container name
        image: mongo-express  # Docker image to use for the container
        ports: 
        - containerPort: 8081  # Port exposed by the container
        env:
        - name: ME_CONFIG_MONGODB_ADMINUSERNAME  # MongoDB admin username environment variable
          value: root  # Value for admin username
        - name: ME_CONFIG_MONGODB_SERVER  # MongoDB server address for Mongo Express to connect to
          value: mongodb-0.mongodb-headless  # MongoDB service address
        - name: ME_CONFIG_MONGODB_ADMINPASSWORD  # MongoDB admin password environment variable
          valueFrom: 
            secretKeyRef:  # Fetch password from Kubernetes secret
              name: mongodb  # Name of the secret
              key: mongodb-root-password  # Key in the secret containing the password
```

### mongo-express-service.yaml

```yaml
apiVersion: v1  # Defines the API version of the service
kind: Service  # Specifies the resource type (Service)
metadata:
  name: mongo-express-service  # Name of the service
spec:
  selector:
    app: mongo-express  # Selector to match the app label for associated pods
  ports:
    - protocol: TCP  # Protocol used for the service (TCP in this case)
      port: 8081  # Port exposed by the service
      targetPort: 8081  # Port on the container that the service will forward traffic to
```

Apply the configurations:

```bash
kubectl apply -f mongo-express-service.yaml
# Deploy the service component first

kubectl apply -f mongo-express-deployment.yaml
# Deploy the deployment component

kubectl get pod
kubectl get service
```

---

## Expose Mongo Express via Ingress for Browser Requests

Install the Ingress Controller:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# Add the ingress-nginx Helm repo

helm repo update
# Update your Helm repo

helm install nginx-ingress ingress-nginx/ingress-nginx
# Install the nginx Ingress controller
```

---

## Create Ingress Routing Rules for Mongo Express

Create a file named `ingress-rule.yaml`:

```yaml
# API version for the Ingress resource
apiVersion: extensions/v1beta1

# Declares this resource as an Ingress
kind: Ingress

metadata:
  # Annotations to specify which Ingress controller to use (nginx in this case)
  annotations:
    kubernetes.io/ingress.class: nginx
  # Name of the Ingress resource
  name: mongo-express

spec:
  rules:
    # Hostname for the ingress rule (external access point)
    - host: nb-139-162-140-213.frankfurt.nodebalancer.linode.com  # Load Balancer Host Name
      http:
        paths:
          # Path to match incoming requests
          - path: /
            backend:
              # Name of the service to route traffic to
              serviceName: mongo-express-service
              # Port on which the service is running
              servicePort: 8081
```

Apply the ingress rule:

```bash
kubectl apply -f ingress-rule.yaml
# Create the ingress rule component

kubectl get ingress
# Check if ingress component is created
```

---

## Accessing the Application Through Browser

Open the following URL in your browser:

```
http://nb-139-162-140-213.frankfurt.nodebalancer.linode.com
```

This project shows how to use an Ingress controller to route external requests from a custom hostname to the internal Mongo Express service in the Kubernetes cluster, enabling browser access to the MongoDB UI through the cluster’s external IP.

---

## License

MIT License
