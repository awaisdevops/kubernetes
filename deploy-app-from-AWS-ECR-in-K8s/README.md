# Deploy App from Private Docker Registry in Kubernetes

## Overview

This project demonstrates how to deploy a custom application in a Kubernetes cluster by pulling Docker images from a private container registry (e.g., AWS Elastic Container Registry - ECR).

---

## Common Workflow of Your Application

A typical CI/CD workflow includes:

1. Code commit to your version control system.
2. Jenkins (or another CI tool) builds and packages the application into a Docker image.
3. The Docker image is pushed to a private registry such as AWS ECR.
4. Kubernetes then pulls the image and runs it in a pod.

> While public images (like MongoDB, Redis, etc.) can be pulled without authentication, custom application images from private registries require proper access setup.

---

## Steps to Pull Docker Images from a Private Registry

To allow Kubernetes to pull images from a private registry, follow these two main steps:

1. **Create a Kubernetes Secret** containing the Docker registry credentials.
2. **Reference the secret** in your deployment or pod using `imagePullSecrets`.

---

## Step #1: Login to AWS and Create a Secret

Get the ECR login token and create a Kubernetes secret that stores your registry credentials:

```bash
kubectl create secret docker-registry my-registry-key \
  --docker-server=809356249122.dkr.ecr.ap-northeast-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=<ECR-login-token>
```
<<<<<<< HEAD
=======

>>>>>>> 4173b04 (Create README.md)
You can also use the following general format:

```bash
kubectl create secret <secret-type> <secret-name> \
  --docker-server=<AWS-ECR-registry-url> \
  --docker-username=<ECR-username> \
  --docker-password=<ECR-password>
```

Check if the secret has been created:

```bash
kubectl get secret
```

---

## Step #2: Create the Deployment Component

Create a YAML file for your Kubernetes deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      imagePullSecrets:
      - name: my-registry-key  #  Secret used to authenticate with AWS ECR
      containers:
      - name: my-app
        image: privat-repo/my-app:1.3  #  ECR-hosted image (should be full ECR URL like <aws_account_id>.dkr.ecr.<region>.amazonaws.com/my-app:1.3)
        imagePullPolicy: Always  #  Always pull the latest version of the image
        ports:
          - containerPort: 3000  #  Exposes port 3000 from the container
```

---

<<<<<<< HEAD
## Deployment
=======
##  Deployment
>>>>>>> 4173b04 (Create README.md)

Apply the deployment using:

```bash
kubectl apply -f my-app-deployment.yaml
```

Check if the pod is up and running:

```bash
kubectl get pods
```

---

<<<<<<< HEAD
## License
=======
##  License
>>>>>>> 4173b04 (Create README.md)

MIT License
