# Complete Jenkins CI/CD Pipeline with AWS ECR Registry

---

This CI/CD pipeline sets up a complete automation flow using Jenkins to build a Java application, package it as a Docker image, push it to AWS ECR (a private container registry), and deploy it to an AWS EKS (Kubernetes) cluster. The pipeline securely uses AWS credentials stored in Jenkins to authenticate with ECR and EKS, and Kubernetes uses an image pull secret to access private images from ECR. Jenkins handles everything from versioning the app, building the image, deploying to EKS, and even committing version changes back to Git—resulting in a fully automated and secure deployment workflow.

---

## Key Pipeline Stages and Their Purpose:

### Create ECR Repository
**Purpose**: Acts as a private Docker image registry for your application.

### Set Up ECR Credentials in Jenkins
Stores AWS credentials (access key & secret) securely to authenticate with ECR during image push.

### Build, Tag, and Push Docker Image
The pipeline builds your app’s Docker image, tags it with ECR repo info, logs in to ECR, and pushes the image.

### Create Kubernetes Secret to Pull from ECR
A Kubernetes Docker registry secret is created to allow your EKS cluster to pull the private image.

### Update Deployment and Service YAMLs
Uses `imagePullSecrets` in deployment YAML to reference the ECR secret and deploy the application using the pushed image.

### Configure Jenkins Pipeline (Jenkinsfile)
Includes all steps: versioning, building, pushing to ECR, applying Kubernetes manifests, and committing back to Git.

---

## 1: Install `gettext-base` Tool on Jenkins Server:

`gettext-base` is a lightweight package from GNU `gettext` that includes essential tools like `envsubst`, a command-line utility used to replace environment variables in files—commonly in DevOps for rendering configuration templates like Kubernetes YAMLs.

```bash
apt update
apt install gettext-base -y
````

> # above tool will make envsubst command available on our jenkins

---

## 2: Create AWS ECR Registry:

We will create an AWS ECR registry and use it to store our docker images. and also use it inside our pipeline to tag, push and pull images.

1. Log in to your AWS Management Console.
2. In the top search bar, type **ECR** and select **Elastic Container Registry**.
3. From the left-hand menu, click on **Repositories**.
4. Click the **Create repository** button.
5. Choose **Private** repository type (default).
6. Enter a **Repository name**, e.g., `java-maven-app`.
7. Optionally configure settings like **Tag immutability**, **Scan on push**, etc.
8. Click **Create repository**.

---

## 3: Set Up AWS ECR Credentials in Jenkins:

### a. Generate the AWS ECR Login Credentials

You’ll need to create an AWS Access Key to use with docker login for ECR authentication.

#### Get the ECR Login Password

To get the ECR login credentials, use the AWS CLI to generate a token for docker login:

```bash
aws ecr get-login-password --region us-east-1
```

This command returns a password that can be used for authentication.

---

### b. Add AWS ECR Credentials to Jenkins as Username with Password

1. Go to Jenkins → **Manage Jenkins** → **Manage Credentials** → (Global) (or in your specific folder if needed).
2. Click **Add Credentials** on the left menu.
3. Set the **Kind** to **Username with password**.
4. Set the **username** to `AWS` (this is the required value for AWS ECR login).
5. Set the **password** to the ECR login password you obtained using the `aws ecr get-login-password` command (or configure a way to dynamically fetch it).
6. **ID**: Choose a recognizable ID for these credentials (e.g., `aws-ecr-username-password`).
7. Optionally, add a **description** for easier identification.
8. Click **OK**.

---

## 4: Create Secret for Kubernetes to Access ECR:

Since Kubernetes needs the credentials to pull images from your private ECR registry, you'll create a Docker registry type secret in Kubernetes to allow EKS to fetch the image.

```bash
kubectl create secret docker-registry aws-registry-key \
  --docker-server=664574038682.dkr.ecr.eu-west-3.amazonaws.com \
  --docker-username=AWS \
  --docker-password=<your-ecr-registry-massword>
# creating secret for aws ecr to be used in our jenkinsfile

kubectl get secret
# confirming if secret is created
```

---

## 5: Create Deployment and Service Components for App deployment:

To deploy a Java Maven app via Jenkins to Kubernetes, dynamic values like app name and image tag are set as environment variables in Jenkins. These variables are injected into Kubernetes YAML templates using `envsubst` (from `gettext-base`), which replaces placeholders like `$APP_NAME`. The final YAML is then applied with `kubectl`. `envsubst` must be manually installed in the Jenkins container.

### `kubernetes/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-maven-app
  labels:
    app: java-maven-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: java-maven-app
  template:
    metadata:
      labels:
        app: java-maven-app
    spec:
      imagePullSecrets:
        - name: aws-registry-key
      containers:
      - name: java-maven-app
        image: docker-hub-registry-name/demo-app:$IMAGE_NAME
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
```

### `kubernetes/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: java-maven-app
spec:
  selector:
    app: java-maven-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```

---

## 6: Configure Jenkins Pipeline:

### `Jenkinsfile`

```groovy
#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'Maven'
    }
    environment {
        ECR_REPO_SERVER = '664574038682.dkr.ecr.eu-west-3.amazonaws.com'
        IMAGE_REPO = "${ECR_REPO_SERVER}/java-maven-app"
    }
    stages {
        stage('increment version') {
            steps {
                script {
                    echo 'incrementing app version...'
                    sh 'mvn build-helper:parse-version versions:set \ 
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                    def version = matcher[0][1]
                    env.IMAGE_NAME = "$version-$BUILD_NUMBER"
                    echo "############ ${IMAGE_REPO}"
                }
            }
        }
        stage('build app') {
            steps {
               script {
                   echo "building the application..."
                   sh 'mvn clean package'
               }
            }
        }
        stage('build image') {
            steps {
                script {
                    echo "building the docker image..."
                    withCredentials([usernamePassword(credentialsId: 'ecr-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sh "docker build -t ${IMAGE_REPO}:${IMAGE_NAME} ."
                        sh "echo $PASS | docker login -u $USER --password-stdin ${ECR_REPO_SERVER}"
                        sh "docker push ${IMAGE_REPO}:${IMAGE_NAME}"
                    }
                }
            }
        }
        stage('deploy') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                APP_NAME = 'java-maven-app'
            }
            steps {
                script {
                    echo 'deploying docker image...'
                    sh 'envsubst < kubernetes/deployment.yaml | kubectl apply -f -'
                    sh 'envsubst < kubernetes/service.yaml | kubectl apply -f -'
                }
            }
        }
        stage('commit version update') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'gitlab-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sh 'git config user.email "jenkins@example.com"'
                        sh 'git config user.name "Jenkins"'
                        sh "git remote set-url origin https://${USER}:${PASS}@gitlab.com/nanuchi/java-maven-app.git"
                        sh 'git add .'
                        sh 'git commit -m "ci: version bump"'
                        sh 'git push origin HEAD:jenkins-jobs'
                    }
                }
            }
        }
    }
}
```

---

## License

```
MIT License

Copyright (c) 2025
