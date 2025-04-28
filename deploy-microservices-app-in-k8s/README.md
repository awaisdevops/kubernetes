# Deploying a Microservices Application in Kubernetes

## Overview
We are deploying a microservices-based online shop application into a Kubernetes cluster. The repository includes the Kubernetes manifests for all microservices required to run the application.

---

## Environment Setup

- Created YAML files with 11 Deployment and corresponding Service manifests.
- Note: All service components are internal (`ClusterIP`) services except the **Frontend** service, which is exposed externally.
- Created a Kubernetes cluster with 3 worker nodes on **Linode** (or any other cloud platform).
- Connected to the cluster.
- Created a **Namespace** and deployed all the microservices into it.
- Accessed the Online Shop from a browser.

---

## Deployment Steps

1. Deploy the necessary third-party services (e.g., Redis).
2. Deploy all microservices in a common namespace.
3. Expose the frontend service via a LoadBalancer.
4. Access the application through the external IP of the frontend service.

---

## Production & Security Best Practices

Following best practices were applied:

- **BP 1**: Added version tags to container images.
- **BP 2**: Configured **Liveness Probes** for each container.
- **BP 3**: Configured **Readiness Probes** for each container.
- **BP 4**: Configured **Resource Requests** for CPU and memory.
- **BP 5**: Configured **Resource Limits** to cap resource usage.
- **BP 6**: Avoided `NodePort` service type for external exposure.
- **BP 7**: Configured multiple replicas where needed.

---

## Information Gathering

To effectively deploy the application, the following information was collected:

1. **List of Microservices**:
    - Email Service
    - Checkout Service
    - Payment Service
    - Product Catalog Service
    - Frontend Service
    - Cart Service
    - Redis (third-party)
    - Currency Service
    - Shipping Service
    - Recommendation Service
    - Ad Service

2. **Communication Details**:
   - Services communicate using gRPC and REST APIs.

3. **Dependencies**:
   - Cart Service depends on Redis.
   - Other services depend on each other as per microservice architecture.

4. **Ports**:
   - Each service runs on specific ports as configured in the Kubernetes manifests.

---

## Preparing the Kubernetes Environment

Steps to prepare the environment:

1. Deploy Redis (third-party service).
2. Create Kubernetes Secrets and ConfigMaps if needed.
3. Develop Kubernetes manifests:
   - Deployment
   - Service
4. Deploy all services into a single namespace for easier management.

---

## Microservices Connection Graph

> 📌 *A visual graph showing microservices and their dependencies would be placed here.*

![Microservices Connection Graph](path/to/your/graph.png)

*Note: You need to replace `path/to/your/graph.png` with the actual graph image location.*

---

## Deployment and Service Configurations

The YAML files provided define Kubernetes Deployments and Services for each microservice. Each deployment:

- Specifies container images with versions.
- Configures liveness and readiness probes.
- Sets CPU and memory resource requests and limits.
- Exposes internal services as `ClusterIP`.
- Exposes the frontend as a `LoadBalancer` service.

Microservices Deployed:
- **emailservice**
- **recommendationservice**
- **paymentservice**
- **productcatalogservice**
- **currencyservice**
- **shippingservice**
- **adservice**
- **cartservice**
- **checkoutservice**
- **frontend** (with external access)
- **redis-cart** (third-party service)

Example snippet for one microservice:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: emailservice
spec:
  selector:
    matchLabels:
      app: emailservice
  template:
    metadata:
      labels:
        app: emailservice
    spec:
      containers:
      - name: server
        image: gcr.io/google-samples/microservices-demo/emailservice:v0.2.3
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        readinessProbe:
          exec:
            command: ["/bin/grpc_health_probe", "-addr=:8080"]
        livenessProbe:
          exec:
            command: ["/bin/grpc_health_probe", "-addr=:8080"]
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
```

---

## License

```
MIT License
