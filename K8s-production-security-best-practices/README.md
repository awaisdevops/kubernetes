# Kubernetes Production Security Best Practices

Securing a Kubernetes (K8s) cluster in production involves multiple layers of defense, from cluster setup and network security to workload configuration and monitoring. This document outlines best practices for Kubernetes production security.

---

## 1. Pinned (Tag) Version for Each Container Image

Always specify explicit image versions in your pod configuration files. Avoid using untagged or `latest` images to ensure consistency and control. Tagged images improve traceability and deployment stability across microservices.

---

## 2. Liveness Probe for Each Container

A **liveness probe** checks if an application inside a pod is healthy. It helps Kubernetes restart unresponsive containers. There are three configuration methods:

### a. Command Execution
```yaml
livenessProbe:
  periodSeconds: 5
  exec:
    command: ["/bin/grpc_health_probe", "-addr=:8080"]
````

### b. TCP Socket

```yaml
livenessProbe:
  initialDelaySeconds: 5
  periodSeconds: 5
  tcpSocket:
    port: 6379
```

### c. HTTP Endpoint

```yaml
livenessProbe:
  initialDelaySeconds: 5
  periodSeconds: 5
  httpGet:
    path: /health
    port: 6379
```

---

## 3. Readiness Probe for Each Container

A **readiness probe** ensures a container is ready to serve traffic before receiving it. It prevents failed requests during startup. Configuration options include:

### a. Command Execution

```yaml
readinessProbe:
  periodSeconds: 5
  exec:
    command: ["/bin/grpc_health_probe", "-addr=:8080"]
```

### b. TCP Socket

```yaml
readinessProbe:
  initialDelaySeconds: 5
  periodSeconds: 5
  tcpSocket:
    port: 6379
```

### c. HTTP Endpoint

```yaml
readinessProbe:
  initialDelaySeconds: 5
  periodSeconds: 5
  httpGet:
    path: /health
    port: 6379
```

---

## 4. Resource Requests for Each Container

Define **resource requests** to guarantee the container receives sufficient CPU and memory.

```yaml
resources:
  requests:
    cpu: 100m
    memory: 64Mi
```

---

## 5. Resource Limits for Each Container

Define **resource limits** to cap the container’s maximum resource usage.

```yaml
resources:
  limits:
    cpu: 200m
    memory: 128Mi
```

---

## 6. Don't Expose the NodePort

Avoid using the `NodePort` service type as it opens a port on every worker node. Instead, prefer:

* `LoadBalancer` for a single external access point.
* `Ingress Controller` for controlled and centralized routing.

---

## 7. More Than 1 Replica for Deployment (at least 2)

Set multiple **replicas** in your Deployment configuration to ensure high availability:

```yaml
replicas: 2
```

---

## 8. More Than 1 Worker Node in Your Cluster

Deploy your Kubernetes cluster with at least **two worker nodes** to avoid a single point of failure and ensure fault tolerance.

---

## 9. Labeling All Your K8s Components

Use **labels** (key-value pairs) on all resources (pods, services, deployments) for better organization, querying, automation, and maintainability.

Example:

```yaml
metadata:
  labels:
    app: my-app
    tier: backend
```

---

## 10. Using Namespaces to Isolate K8s Resources

Use **namespaces** to group and isolate resources. Namespaces support:

* Better organization
* Role-based access control (RBAC)
* Multi-team and multi-environment separation

---

## 11. Scan Images for Security Vulnerabilities

Use tools like **Trivy** to scan container images:

* Before deployment:

  ```bash
  trivy image your-image-name:tag
  ```
* After deployment:

  ```bash
  kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].image}'
  trivy image <image-name>
  ```
* Cluster-wide scanning:
  Install **Trivy Operator** to continuously monitor running workloads.

---

## 12. No Root Access for Containers

Run containers as **non-root** users to enforce the principle of least privilege and reduce security risks.

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
```

---

## License

[MIT](LICENSE)
