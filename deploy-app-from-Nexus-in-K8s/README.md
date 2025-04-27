## Deploying Application from Nexus Private Registry in Kubernetes Cluster

Deploying an application from a **Nexus private Docker registry** into a **Kubernetes cluster** is quite similar to using AWS ECR. Here’s a clear step-by-step guide:

---

### Step 1: Login to Nexus & Create Kubernetes Secret

First, get your Nexus Docker registry credentials:

- `Nexus URL`: e.g., `https://nexus.example.com`
- `Username`: Your Nexus login username
- `Password`: Your Nexus login password
- `Email`: Any valid email (Nexus may require this, even if unused)

Create a Kubernetes secret with these credentials:

```bash
kubectl create secret docker-registry nexus-registry-key \
  --docker-server=nexus.example.com \
  --docker-username=<your-nexus-username> \
  --docker-password=<your-nexus-password> \
  --docker-email=<your-email>
```

💡 Replace `nexus.example.com` with the actual Docker registry hostname (not including `https://` or `/repository/`).

---

### Step 2: Create Deployment YAML

Reference the secret in your pod spec using `imagePullSecrets` and use the Nexus image path:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nexus-app
  labels:
    app: my-nexus-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-nexus-app
  template:
    metadata:
      labels:
        app: my-nexus-app
    spec:
      imagePullSecrets:
      - name: nexus-registry-key  # Secret used to authenticate with Nexus private registry
      containers:
      - name: my-nexus-app
        image: nexus.example.com/my-project/my-app:1.0  # Full Nexus image URL
        imagePullPolicy: Always  # Always pull the latest version
        ports:
          - containerPort: 8080  # Expose app port
```

---

###  Step 3: Apply the Deployment

```bash
kubectl apply -f my-nexus-app-deployment.yaml
```

Then confirm:

```bash
kubectl get pods
kubectl describe pod <pod-name>  # Check if image pulls successfully
```

---
