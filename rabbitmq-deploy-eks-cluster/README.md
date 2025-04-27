# Deploy and Configure RabbitMQ in AWS EKS Cluster

This project exolains how to deploy and configure **RabbitMQ** as a **message broker inside an AWS EKS cluster**, including options for secure setups. 

---

# 1. Add RabbitMQ Helm Repository

First, add Bitnami's Helm repository (they maintain official RabbitMQ charts):

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
# Add the Bitnami Helm chart repository

helm repo update
# Update the local Helm chart repository list

```

---

# 2. Create a Namespace for RabbitMQ

Organize RabbitMQ into its own namespace:

```bash
kubectl create namespace rabbitmq
# Create a new Kubernetes namespace for RabbitMQ

kubectl get namespaces
# Get the list of all namespaces in the Kubernetes cluster

```

---

# 3. Deploy RabbitMQ Using Helm

Install RabbitMQ into your EKS cluster:

```bash
helm install rabbitmq bitnami/rabbitmq --namespace rabbitmq
#Install RabbitMQ into your EKS cluster
```

✅ This installs:

- RabbitMQ server
- RabbitMQ management UI
- Necessary Kubernetes services
- PVCs (Persistent Volume Claims) for data persistence

---

# 4. Verify Deployment

Check all resources in the `rabbitmq` namespace:

```bash
kubectl get all -n rabbitmq
# Get all resources (pods, services, deployments, etc.) in the 'rabbitmq' namespace
```

You should see:

- Pods
- Services
- StatefulSet
- ConfigMaps
- Secrets

---

# 5. Access RabbitMQ Credentials

RabbitMQ credentials (username/password) are stored in Kubernetes Secrets.

Retrieve them:

```bash
kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-username}" | base64 -d
echo
# Get the default username

kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 -d
echo
# Get the default password
```

By default, it’s usually:

- **Username:** `user`
- **Password:** (generated random password)

---

# 6. Access RabbitMQ Management UI (Port Forward)

RabbitMQ dashboard runs on port **15672**.

To access it locally:

```bash
kubectl port-forward --namespace rabbitmq svc/rabbitmq 15672:15672
# Forward port 15672 from the RabbitMQ service to your local machine for accessing the RabbitMQ management interface
```

Open your browser:

```
http://127.0.0.1:15672
```

Use the credentials retrieved earlier to log in.

---

# 7. Create a Custom `values.yaml` (optional but recommended)

If you want **custom settings** like setting **static credentials**, **node selectors**, **persistence**, **replicas**, and **resources**, you can create a `values.yaml` like:

```yaml
# Authentication settings
auth:
  username: myuser
  password: mysecurepassword
  erlangCookie: mysupersecreterlangcookie

# Number of replicas (instances)
replicaCount: 2

# Persistent storage configuration
persistence:
  enabled: true
  storageClass: "gp2"
  accessModes:
    - ReadWriteOnce
  size: 8Gi

# Resource requests and limits
resources:
  requests:
    memory: 512Mi
    cpu: 250m
  limits:
    memory: 1024Mi
    cpu: 500m

# Service configuration
service:
  type: LoadBalancer

# RBAC (Role-Based Access Control) settings
rbac:
  create: true

# Metrics and monitoring configuration
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
```

> Save this file as `rabbitmq-values.yaml`.

Then deploy RabbitMQ with your custom config:

```bash
helm install rabbitmq bitnami/rabbitmq -n rabbitmq -f rabbitmq-values.yaml
# Install RabbitMQ using Helm with a custom values file in the 'rabbitmq' namespace
```

---

# 8. Exposing RabbitMQ to External Traffic (Optional)

If you used `service.type: LoadBalancer` in `values.yaml`, a public AWS ELB will be created.

Check the external IP:

```bash
kubectl get svc -n rabbitmq
# Get the list of services in the 'rabbitmq' namespace
```

Look for an **EXTERNAL-IP** assigned to the RabbitMQ service.

---

# 9. RabbitMQ Connection URL

Once deployed, your apps can connect like this:

```
amqp://<rabbitmq-username>:<rabbitmq-password>@<rabbitmq-service-host>:5672/
```

- `5672` → default AMQP port
- `15672` → RabbitMQ UI port (for management only)

Example:

```
amqp://user:password@rabbitmq.rabbitmq.svc.cluster.local:5672/
```

---

# 10. Optional - Production-Level Enhancements

- **Enable TLS**: Bitnami Helm charts allow enabling TLS easily with a certificate manager.
- **Cluster Operator**: If you want more advanced clustering (multi-AZ RabbitMQ clusters), consider Bitnami’s **RabbitMQ Cluster Operator**.
- **Persistence**: Always keep persistence enabled for production to avoid data loss.
- **Metrics**: Enable metrics for Prometheus/Grafana monitoring.

---

# Full Quick Commands Summary:

```bash
# Add the Bitnami Helm chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update the Helm repositories
helm repo update

# Create the RabbitMQ namespace in Kubernetes
kubectl create namespace rabbitmq

# Install RabbitMQ using Helm in the 'rabbitmq' namespace
helm install rabbitmq bitnami/rabbitmq --namespace rabbitmq

# Get all resources (pods, services, deployments, etc.) in the 'rabbitmq' namespace
kubectl get all -n rabbitmq

# Get the RabbitMQ username from the Kubernetes secret and decode it from base64
kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-username}" | base64 -d

# Get the RabbitMQ password from the Kubernetes secret and decode it from base64
kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 -d

# Forward port 15672 from the RabbitMQ service to your local machine for accessing the RabbitMQ management interface
kubectl port-forward --namespace rabbitmq svc/rabbitmq 15672:15672

# (Optional) Install RabbitMQ using Helm with a custom values file in the 'rabbitmq' namespace
helm install rabbitmq bitnami/rabbitmq -n rabbitmq -f rabbitmq-values.yaml

```

---

# License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```
