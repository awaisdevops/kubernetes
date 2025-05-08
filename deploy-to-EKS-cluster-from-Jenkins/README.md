# Deploy to EKS Cluster from Jenkins

We are assuming that you already have an AWS EKS cluster up and running.

Before we proceed deploying our application to the cluster, we need to configure the following on the Jenkins server:

## 1. Install Required Tools in Jenkins

- `kubectl`: for interacting with the Kubernetes cluster  
- `aws-iam-authenticator`: for authenticating with AWS

## 2. Configure Kubernetes Access

- Create a Kubernetes `config` file on the Jenkins server

## 3. Create IAM User for Jenkins

## 4. Setup AWS Authentication

- Provide AWS credentials (Access Key ID and Secret Access Key) to Jenkins  
- Required for cluster and AWS API access

## 5. Final Integration

- Update the `Jenkinsfile` to run `kubectl` commands  
- Deploy workloads to EKS directly from the pipeline

---

## 1: Install kubectl on Jenkins Server

We need the kubectl command-line tool installed on the Jenkins server so that Jenkins pipelines can execute kubectl commands to interact with the Kubernetes cluster.

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
# Update the package list and install required dependencies

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
# Download the Google Cloud public signing key

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
# Add the Kubernetes APT repository

sudo apt-get update
# Update the package list with the new Kubernetes repo

sudo apt-get install -y kubectl
# Install kubectl

kubectl version --client
# Verify that kubectl is installed correctly
```
---

## 2: Install AWS IAM Authenticator

After installing kubectl, we need the aws-iam-authenticator for AWS. The kubeconfig file created during EKS cluster setup contains the credentials and certificates for authentication. To enable Jenkins to interact with the cluster, both tools are required. Let’s set this up next.

```bash
curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/latest/bin/linux/amd64/aws-iam-authenticator
# Download the latest AWS IAM Authenticator binary for Linux

chmod +x aws-iam-authenticator
# Make the binary executable

sudo mv aws-iam-authenticator /usr/local/bin/
# Move the binary to a directory in your system PATH

aws-iam-authenticator help
# Verify the installation
```
---

## 3: Create IAM User for Jenkins

For integrating Jenkins inside our pipeline, it's best practice to create a dedicated IAM user with only the necessary permissions. This improves security by avoiding admin-level access and allows Jenkins to authenticate safely with services like AWS, Kubernetes, and Docker repositories.

Log in to the AWS Management Console → type IAM in the search bar → select IAM → go to Users → click Add user → enter a username (e.g., `jenkins-pipeline-user`) → choose Programmatic access → click Next: Permissions → choose Attach policies directly → select AmazonEKSFullAccess and AmazonS3ReadOnlyAccess → click Next: Tags (optional) → click Next: Review → review and click Create user → save the Access Key ID and Secret Access Key for Jenkins pipeline use.

---

## 4: Create kube/config File for Jenkins Server

We’ll create a Kubernetes config file in the Jenkins container to authenticate with AWS and the EKS cluster, replacing the need for Jenkins UI credentials. This file, similar to the local kubeconfig, contains the necessary authentication details for cluster access.

```bash
aws eks --region  update-kubeconfig --name 
# Creates or updates the kubeconfig file at ~/.kube/config with access details for the specified EKS cluster
#  is your AWS region (e.g., us-east-1)
#  is the name of your EKS cluster

aws eks --region us-east-1 update-kubeconfig --name my-eks-cluster
# Connects kubectl to the EKS cluster named "my-eks-cluster" in the "us-east-1" region by generating the config file
```
---

## 5: Create AWS Credentials for Jenkins IAM User

We create these AWS Access Key ID and Secret Access Key secrets in Jenkins to securely authenticate the Jenkins pipeline with AWS services (e.g., EKS). Instead of hardcoding sensitive credentials, we store them as "Secret text" credentials and reference them in the pipeline for secure access.

### AWS Access Key ID

Go to Manage Jenkins → Manage Credentials → select a domain → click Add Credentials → choose Kind: Secret text → enter AWS Access Key ID as the secret → set ID to aws-access-key-id → click OK.

### AWS Secret Access Key

Go to Manage Jenkins → Manage Credentials → select a domain → click Add Credentials → choose Kind: Secret text → enter AWS Secret Access Key as the secret → set ID to aws-secret-access-key → click OK.

---

## 6: Configure Jenkinsfile to Deploy to EKS Cluster

The kubectl command uses the config file located at ~/.kube/config, which is set up to use the AWS IAM Authenticator for authentication. When kubectl runs, the authenticator is triggered in the background and requires AWS credentials, which are provided as environment variables in the Jenkins pipeline.

**Jenkinsfile:**

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
            environment {
               AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
               AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
            }
            steps {
                script {
                   echo 'deploying docker image...'
                   sh 'kubectl create deployment nginx-deployment --image=nginx'
                }
            }
        }
    }
}
```
---

**nginx-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
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
          image: nginx:latest
          ports:
            - containerPort: 80
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

## License

MIT License

Copyright (c) 2025
