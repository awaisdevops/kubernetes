# Deploy and Configure RabbitMQ in AWS EKS

This project contains a stpe by stpe guide to deploy and configure **RabbitMQ** as a **message broker inside an AWS EKS cluster**, including options for secure setups. 

---

---

## 1. Add RabbitMQ Helm Repository

Add Bitnami's Helm repository:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
2. Create a Namespace for RabbitMQ
Create a separate namespace:

bash
Copy
Edit
kubectl create namespace rabbitmq
(Optional) Check namespaces:

bash
Copy
Edit
kubectl get namespaces
3. Deploy RabbitMQ Using Helm
Install RabbitMQ into your EKS cluster:

bash
Copy
Edit
helm install rabbitmq bitnami/rabbitmq --namespace rabbitmq
This installs:

RabbitMQ server

RabbitMQ management UI

Necessary Kubernetes services

PVCs (Persistent Volume Claims) for data persistence

4. Verify Deployment
Check all resources in the rabbitmq namespace:

bash
Copy
Edit
kubectl get all -n rabbitmq
You should see:

Pods

Services

StatefulSet

ConfigMaps

Secrets

5. Access RabbitMQ Credentials
Retrieve the auto-generated credentials:

bash
Copy
Edit
# Get the default username
kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-username}" | base64 -d
echo

# Get the default password
kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 -d
echo
By default:

Username: user

Password: (generated random password)

6. Access RabbitMQ Management UI (Port Forward)
Access the RabbitMQ dashboard on port 15672:

bash
Copy
Edit
kubectl port-forward --namespace rabbitmq svc/rabbitmq 15672:15672
Open:

cpp
Copy
Edit
http://127.0.0.1:15672
Use the retrieved credentials to log in.

7. Create a Custom values.yaml (optional but recommended)
For custom settings, create a values.yaml:

yaml
Copy
Edit
auth:
  username: myuser
  password: mysecurepassword
  erlangCookie: mysupersecreterlangcookie

replicaCount: 2

persistence:
  enabled: true
  storageClass: "gp2"
  accessModes:
    - ReadWriteOnce
  size: 8Gi

resources:
  requests:
    memory: 512Mi
    cpu: 250m
  limits:
    memory: 1024Mi
    cpu: 500m

service:
  type: LoadBalancer

rbac:
  create: true

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
Save it as rabbitmq-values.yaml.

Deploy with:

bash
Copy
Edit
helm install rabbitmq bitnami/rabbitmq -n rabbitmq -f rabbitmq-values.yaml
8. Exposing RabbitMQ to External Traffic (Optional)
If you used service.type: LoadBalancer, a public AWS ELB will be created.

Check the external IP:

bash
Copy
Edit
kubectl get svc -n rabbitmq
Look for an EXTERNAL-IP field.

9. RabbitMQ Connection URL Example
Connect to RabbitMQ:

php-template
Copy
Edit
amqp://<rabbitmq-username>:<rabbitmq-password>@<rabbitmq-service-host>:5672/
Example:

pgsql
Copy
Edit
amqp://user:password@rabbitmq.rabbitmq.svc.cluster.local:5672/
10. Optional - Production-Level Enhancements
Enable TLS: Bitnami Helm charts allow easy TLS configuration.

Cluster Operator: For multi-AZ high availability.

Persistence: Always enable persistence for production.

Metrics: Integrate with Prometheus/Grafana for monitoring.

11. Upgrade / Uninstall RabbitMQ
To upgrade:

bash
Copy
Edit
helm upgrade rabbitmq bitnami/rabbitmq -n rabbitmq -f rabbitmq-values.yaml
To uninstall:

bash
Copy
Edit
helm uninstall rabbitmq -n rabbitmq
Clean up namespace:

bash
Copy
Edit
kubectl delete namespace rabbitmq
🎯 Full Quick Commands Summary
bash
Copy
Edit
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

kubectl create namespace rabbitmq

helm install rabbitmq bitnami/rabbitmq --namespace rabbitmq

kubectl get all -n rabbitmq

kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-username}" | base64 -d
kubectl get secret --namespace rabbitmq rabbitmq -o jsonpath="{.data.rabbitmq-password}" | base64 -d

kubectl port-forward --namespace rabbitmq svc/rabbitmq 15672:15672

# (Optional custom config)
helm install rabbitmq bitnami/rabbitmq -n rabbitmq -f rabbitmq-values.yaml

License
This project is licensed under the MIT License.

sql
Copy
Edit

---
