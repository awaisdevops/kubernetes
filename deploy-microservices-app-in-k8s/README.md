# Deploying a Microservices Application in Kubernetes

We're deploying a microservices-based **online shop application** into a Kubernetes cluster. This guide covers the process from preparing manifests to applying production best practices.

![Sample Image](assets/1.PNG)

---

## Complete Process Workflow

This section focuses on deployment details: which microservices are involved, how they communicate, and their dependencies on third-party services or databases.

For example, some services use a message broker, others require a database. It's important to identify the entry-point microservice that handles browser requests.

### ✅ Key Steps:

- ✅ Created YAML files with **11 Deployment** and corresponding **Service manifests**
- ✅ All services are internal **except** the **Frontend Service**, which is accessible from a browser
- ✅ Created a Kubernetes cluster with **3 Worker Nodes** (e.g., on Linode or other cloud platforms)
- ✅ Connected to the cluster
- ✅ Created a **Namespace** and deployed all microservices
- ✅ Accessed the Online Shop via a browser

---

## Production & Security Best Practices

- **BP 1**: Added version to each container image  
- **BP 2**: Configured **Liveness Probes**  
- **BP 3**: Configured **Readiness Probes**  
- **BP 4**: Set **Resource Requests**  
- **BP 5**: Set **Resource Limits**  
- **BP 6**: Avoided using **NodePort** service type  
- **BP 7**: Configured **more than 1 replica** for each Deployment  

---

## List of the Microservices in the Application

The application consists of the following microservices:

- `emailservice`
- `recommendationservice`
- `paymentservice`
- `productcatalogservice`
- `currencyservice`
- `shippingservice`
- `adservice`
- `cartservice`
- `checkoutservice`
- `frontend` _(with external access)_
- `redis-cart` _(third-party service)_

---

## Microservices Connection Graph

A connection graph helps visualize how services interact.

![Sample Image](assets/1.PNG)

---

## Deployment and Service Configurations

We created 11 YAML files—1 for each deployment and its corresponding service.

```bash
kubectl apply -f emailservice.yaml
```

```yaml
---
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
        - name: DISABLE_TRACING
          value: "1"
        - name: DISABLE_PROFILER
          value: "1"
        readinessProbe:
          periodSeconds: 5
          exec:
            command: ["/bin/grpc_health_probe", "-addr=:8080"]
        livenessProbe:
          periodSeconds: 5
          exec:
            command: ["/bin/grpc_health_probe", "-addr=:8080"]
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: emailservice
spec:
  type: ClusterIP
  selector:
    app: emailservice
  ports:
  - protocol: TCP
    port: 5000
    targetPort: 8080
```

To apply the configuration:

```bash
kubectl apply -f emailservice.yaml
```

---

## Notes

- Make sure to maintain consistent naming across deployment and service manifests.
---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```

---
