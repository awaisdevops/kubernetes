# Complete Jenkins CI/CD Pipeline with DockerHub

This project sets up a CI/CD pipeline in Jenkins to automate the deployment of a Java (Maven-based) application to a Kubernetes cluster, using Docker Hub for image storage.

---

## Key Steps

### Install `gettext-base` on Jenkins Server

This provides the `envsubst` command, which replaces environment variables (like `$APP_NAME`, `$IMAGE_NAME`) in Kubernetes YAML files at runtime.

### Templated Kubernetes YAMLs

- `deployment.yaml` and `service.yaml` use variables like `$APP_NAME` and `$IMAGE_NAME`.
- These templates are dynamically rendered using `envsubst` during the deploy stage.

### Create Docker Hub Registry Secret in Kubernetes

A one-time `kubectl create secret docker-registry` command is run to allow Kubernetes to pull private images from Docker Hub.

---

## Jenkins Pipeline Breakdown

- **Versioning**: Maven plugin updates the app version based on the previous version and build number.
- **Build App**: Runs `mvn clean package` to build the JAR.
- **Build & Push Docker Image**: Jenkins builds and pushes the Docker image to Docker Hub using stored credentials.
- **Deploy to Kubernetes**: Jenkins uses `envsubst` and `kubectl apply` to deploy the updated app.
- **Git Commit**: Jenkins commits the new version back to GitLab using Git credentials.

---

## 1. Install `gettext-base` tool on Jenkins Server

`gettext-base` is a lightweight package from GNU `gettext` that includes essential tools like `envsubst`, a command-line utility used to replace environment variables in files—commonly in DevOps for rendering configuration templates like Kubernetes YAMLs.

```bash
apt update
apt install gettext-base -y
# above tool will make envsubst command available on our Jenkins 
````

---

## 2. Create Secret for DockerHub Registry in EKS cluster

To allow Kubernetes to pull images from a private Docker Hub repository, a **Docker registry secret** must be created using `kubectl`. This is typically a one-time setup per namespace and is best done manually, though it can be automated for multi-namespace or microservice environments.

```bash
kubectl create secret docker-registry my-registry-key \
  --docker-server=docker.io \
  --docker-username=<dockerhub-registry-username> \
  --docker-password=<your-password>

kubectl get secret
# to confirm if secret is created
```

---

## 3. Create Deployment and Service Components for App deployment

To deploy a Java Maven app via Jenkins to Kubernetes, dynamic values like app name and image tag are set as environment variables in Jenkins. These variables are injected into Kubernetes YAML templates using `envsubst` (from gettext-base), which replaces placeholders like `$APP_NAME`. The final YAML is then applied with `kubectl`. `envsubst` must be manually installed in the Jenkins container.

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
        - name: my-registry-key
      containers:
      - name: java-maven-app
        image: docker-hub-registry-name/demo-app:$IMAGE_NAME
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
```

---

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

## 4. Configure Jenkins Pipeline

### `Jenkinsfile`

```groovy
#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'Maven'  // Use Maven tool named 'Maven' configured in Jenkins
    }
    stages {
        stage('increment version') {
            steps {
                script {
                    echo 'incrementing app version...'  // Log version increment step
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\${parsedVersion.majorVersion}.\\${parsedVersion.minorVersion}.\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'  // Increment version using Maven plugins
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'  // Extract version from pom.xml
                    def version = matcher[0][1]
                    env.IMAGE_NAME = "$version-$BUILD_NUMBER"  // Set IMAGE_NAME env variable with version and build number
                }
            }
        }
        stage('build app') {
            steps {
                script {
                    echo "building the application..."  // Log build step
                    sh 'mvn clean package'  // Build the app using Maven
                }
            }
        }
        stage('build image') {
            steps {
                script {
                    echo "building the docker image..."  // Log docker image build step
                    withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sh "docker build -t nanajanashia/demo-app:${IMAGE_NAME} ."  // Build docker image with tag
                        sh "echo $PASS | docker login -u $USER --password-stdin"  // Login to Docker Hub securely
                        sh "docker push nanajanashia/demo-app:${IMAGE_NAME}"  // Push docker image to Docker Hub
                    }
                }
            }
        }
        stage('deploy') {
            environment {
                APP_NAME = 'java-maven-app'  // Set application name environment variable
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')  // AWS Access Key from Jenkins credentials
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')  // AWS Secret Key from Jenkins credentials
            }
            steps {
                script {
                    echo "deploying docker image..."  // Log deployment step
                    sh 'envsubst < kubernetes/deployment.yaml | kubectl apply -f -'  // Deploy Kubernetes deployment manifest
                    sh 'envsubst < kubernetes/service.yaml | kubectl apply -f -'  // Deploy Kubernetes service manifest
                }
            }
        }
        stage('commit version update') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'gitlab-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        // Configure git user for committing version bump
                        sh 'git config --global user.email "jenkins@example.com"'
                        sh 'git config --global user.name "jenkins"'

                        sh "git remote set-url origin https://${USER}:${PASS}@gitlab.com/nanuchi/java-maven-app.git"  // Set authenticated git remote URL
                        sh 'git add .'  // Stage all changes
                        sh 'git commit -m "ci: version bump"'  // Commit version bump
                        sh 'git push origin HEAD:jenkins-jobs'  // Push changes to jenkins-jobs branch
                    }
                }
            }
        }
    }
}

```

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

```
MIT License

Copyright (c) 2025
