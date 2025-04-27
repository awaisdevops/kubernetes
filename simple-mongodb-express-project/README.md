# MongoDB + Mongo Express Deployment on Kubernetes

## Project Demo

In this simple project, I outlined the process of deploying two applications—MongoDB and Mongo Express. It is demonstrated to showcase a typical web application setup with a database. The deployment begins by creating a MongoDB pod along with an internal service, ensuring only other components within the same Kubernetes cluster can communicate with it. Next, a Mongo Express deployment is set up, requiring the MongoDB database URL and authentication credentials. These are passed into Mongo Express via environment variables, using a ConfigMap for the URL and a Secret for the credentials. To make Mongo Express accessible through a browser, an external service is created, allowing incoming HTTP requests to reach the Mongo Express pod. The request flow starts from the browser, reaches the external service, is forwarded to the Mongo Express pod, which connects to the internal MongoDB service, and communicates with the MongoDB pod using the provided credentials for authentication. This setup provides a simple yet effective way to connect a frontend application to a backend database within a Kubernetes environment.

---

## Minikube and Kubectl Installation

```bash
sudo apt update && sudo apt install -y curl apt-transport-https virtualbox virtualbox-ext-pack
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v1.30.0/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/
minikube start
kubectl version
minikube start --driver=docker
```

## Kubernetes Components Configurations Files

Below are given the configurations files of all the k8s components used with the proper description of each step.

### vim ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: name  # Name of the Ingress resource
  annotations:
    kubernetes.io/ingress.class: "nginx"  # Annotation to specify the NGINX Ingress controller
spec:
  rules:
    - host: app.com  # Domain name for routing the request
      http:
        paths:
          - path: /  # Path to match for incoming HTTP requests
            backend:
              serviceName: my-service  # Name of the backend service to forward requests to
              servicePort: 8080  # Port on the service to forward the request to
```

---

### vim mongo-configmap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongodb-configmap  # Name of the ConfigMap
data:
  database_url: mongodb-service  # MongoDB service URL
```

---

### vim mongo-express.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-express  # Name of the Deployment
  labels:
    app: mongo-express  # Label used to organize and select objects
spec:
  replicas: 1  # Number of desired pod replicas
  selector:
    matchLabels:
      app: mongo-express  # Selector to match the pods with the same label
  template:
    metadata:
      labels:
        app: mongo-express  # Labels for the pods created by this Deployment
    spec:
      containers:
      - name: mongo-express  # Container name
        image: mongo-express  # Docker image to use
        ports:
        - containerPort: 8081  # Port exposed by the container
        env:
        - name: ME_CONFIG_MONGODB_ADMINUSERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret  # Name of the Secret containing credentials
              key: mongo-root-username  # Key within the Secret for the username
        - name: ME_CONFIG_MONGODB_ADMINPASSWORD
          valueFrom: 
            secretKeyRef:
              name: mongodb-secret  # Secret name
              key: mongo-root-password  # Key for the password
        - name: ME_CONFIG_MONGODB_SERVER
          valueFrom: 
            configMapKeyRef:
              name: mongodb-configmap  # ConfigMap name
              key: database_url  # Key in the ConfigMap for the database URL
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-express-service  # Name of the Service
spec:
  selector:
    app: mongo-express  # Selects pods with this label
  type: LoadBalancer  # Exposes the service externally using a cloud provider's load balancer
  ports:
    - protocol: TCP  # Network protocol used
      port: 8081  # Port exposed by the Service
      targetPort: 8081  # Port the container is listening on
      nodePort: 30000  # (Optional) Port exposed on each Node (used with type: NodePort or LoadBalancer)
```

---

### Base64 Encoding/Decoding for Secret

```bash
echo -n 'admin' | base64           # For db username
echo -n 'admin123' | base64        # For db password

echo -n 'base64-encoded-value' | base64 -d  # To decode
```

---

### vim mongo-secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret  # Name of the Secret
type: Opaque  # Type of the Secret (Opaque means it contains arbitrary user-defined data)
data:
  mongo-root-username: dXNlcm5hbWU=  # Base64-encoded username (e.g., 'username')
  mongo-root-password: cGFzc3dvcmQ=  # Base64-encoded password (e.g., 'password')
```

---

### vim mongo.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb-deployment  # Name of the Deployment
  labels:
    app: mongodb  # Label for organizing/selecting this deployment
spec:
  replicas: 1  # Number of pod replicas to run
  selector:
    matchLabels:
      app: mongodb  # Selector to match pods with this label
  template:
    metadata:
      labels:
        app: mongodb  # Label assigned to the pods
    spec:
      containers:
      - name: mongodb  # Name of the container
        image: mongo  # MongoDB container image
        ports:
        - containerPort: 27017  # Port that MongoDB listens on inside the container
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret  # Refers to the Secret named 'mongodb-secret'
              key: mongo-root-username  # Key inside the Secret for the username
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom: 
            secretKeyRef:
              name: mongodb-secret  # Refers to the same Secret
              key: mongo-root-password  # Key inside the Secret for the password
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service  # Name of the Service
spec:
  selector:
    app: mongodb  # Selects the pods labeled 'app: mongodb'
  ports:
    - protocol: TCP  # Network protocol used
      port: 27017  # Port exposed by the Service
      targetPort: 27017  # Port on the container the Service forwards to
```

---

## Creating the Components using kubectl (in order)

```bash
kubectl apply -f mongo-secret.yaml  # Create the Secret containing MongoDB credentials
kubectl apply -f mongo.yaml         # Deploy the MongoDB pod and its internal service
kubectl apply -f mongo-configmap.yaml  # Create the ConfigMap with the MongoDB connection URL
kubectl apply -f mongo-express.yaml  # Deploy Mongo Express and expose it via an external service
```

---

## kubectl get commands (to check status and resources)

```bash
kubectl get pod  # List all pods in the current namespace
kubectl get pod --watch  # Continuously watch for pod status updates in real time
kubectl get pod -o wide  # Get more detailed info including node assignment and IPs
kubectl get service  # List all services (ClusterIP, NodePort, etc.)
kubectl get secret  # List all Secrets (credentials, tokens, etc.)
kubectl get all | grep mongodb  # Filter and view all MongoDB-related resources
```

---

## kubectl debugging commands

```bash
kubectl describe pod mongodb-deployment-xxxxxx  # Show detailed info and events for the MongoDB pod
kubectl describe service mongodb-service  # View service details including endpoints and selector labels
kubectl logs mongo-express-xxxxxx  # View logs from the Mongo Express pod
```

> Replace `xxxxxx` with the actual pod name.

---

## Access external service in Minikube

```bash
minikube service mongo-express-service  # Open Mongo Express in the default browser using its exposed NodePort URL
```

This will open a URL like:

```
http://<minikube-ip>:<node-port>
http:192.168.64.5:30000
```

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
