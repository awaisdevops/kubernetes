# Deploy to Linode LKE Cluster from Jenkins

This project demonstrates how to deploy an application from Jenkins to a Kubernetes cluster hosted on **Linode Kubernetes Engine (LKE)**. Compared to platforms like AWS EKS, Linode simplifies the authentication process and offers easier environment portability.

---

## Steps to Deploy to Linode LKE from Jenkins

1. [Create Linode LKE Cluster](#1-create-linode-lke-cluster)
2. [Install `kubectl`](#2-kubectl-installation)
3. [Connect to LKE Cluster](#3-connect-to-lke-cluster)
4. [Add LKE Kubeconfig to Jenkins](#4-add-lke-kubeconfig-to-jenkins-as-a-secret-file)
5. [Install Kubernetes CLI Plugin in Jenkins](#5-install-kubernetes-cli-plugin-on-jenkins)
6. [Configure Jenkinsfile and YAML](#6-configure-jenkinsfile-to-deploy-lke-cluster)

---

## 1. Create Linode LKE Cluster

To create a Kubernetes (LKE) cluster from the Linode Cloud Manager UI:

- Log in to your Linode Cloud Manager account.
- Click **Create** and select **Kubernetes**.
- On the "Create a Kubernetes Cluster" page:
  - Enter a **Cluster Label**.
  - Choose a **Region**.
  - Select a **Kubernetes Version**.
  - Add a **Node Pool** with your preferred instance type and number of nodes.
- Click **Create Cluster**.

---

## 2. Kubectl Installation

Ensure `kubectl` is installed on the Jenkins server:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt-get update
sudo apt-get install -y kubectl

kubectl version --client
````

---

## 3. Connect to LKE Cluster

Download the kubeconfig file from your LKE dashboard.

```bash
export KUBECONFIG=path/to/kubeconfig.yaml
kubectl get nodes
```

---

## 4. Add LKE Kubeconfig to Jenkins as a Secret File

1. In Jenkins, go to:
   `Manage Jenkins` → `Credentials` → (select scope) → `Add Credentials`

2. Fill out the form:

   * **Kind:** Secret file
   * **File:** Upload your kubeconfig file (e.g., `lke-kubeconfig.yaml`)
   * **ID:** `lke-kubeconfig` (you will reference this in your pipeline)
   * **Description:** e.g., Linode LKE Kubeconfig

3. Click **OK** to save.

---

## 5. Install Kubernetes CLI Plugin on Jenkins

1. Go to:
   `Manage Jenkins` → `Plugins` → `Available`

2. Search for `Kubernetes CLI Plugin`.

3. Check the box and click **Install without restart**.

4. Confirm installation under the **Installed** tab.

---

## 6. Configure Jenkinsfile to Deploy LKE Cluster

### Jenkinsfile

```groovy
#!/usr/bin/env groovy
pipeline {
    agent any
    stages {
        stage('build app') {
            steps {
                script {
                    echo "building the application..."
                }
            }
        }
        stage('build image') {
            steps {
                script {
                    echo "building the docker image..."
                }
            }
        }
        stage('deploy') {
            steps {
                script {
                    echo 'deploying docker image...'
                    withKubeConfig(
                        [credentialsId: 'kubeconfig-credentials-id', serverUrl: 'https://your-k8s-api-server']
                    ) {
                        sh 'kubectl create deployment nginx-deployment --image=nginx'
                    }
                }
            }
        }
    }
}
```

> ✅ Replace `kubeconfig-credentials-id` with the actual Jenkins credential ID.
> ✅ Replace `https://your-k8s-api-server` with your actual LKE API server URL.

---

### nginx-deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.25.3  # Use a stable version
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "250m"
              memory: "256Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

---

## ✅ Summary

This guide helps you set up a Jenkins CI/CD pipeline that can deploy workloads to a Kubernetes cluster on Linode. It covers infrastructure setup, secure credential management, and Jenkins pipeline configuration.

---
