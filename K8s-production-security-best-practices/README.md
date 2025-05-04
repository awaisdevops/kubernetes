# Kubernetes Production Security Best Practices

Securing a Kubernetes (K8s) cluster in production involves multiple layers of defense—from cluster setup and network security to workload configuration and monitoring. Here's a list of best practices for Kubernetes production security:

---

## 1: Pinned (Tag) Version for Each Container Image

One key Kubernetes best practice is to **always specify explicit image versions** in your pod configuration files. Using untagged or "latest" images leads to unpredictability, as Kubernetes will pull the newest image version each time a pod restarts, making it hard to track what is running in the cluster. To ensure consistency and control, all images should be tagged with a specific version across all microservices. This approach provides clear visibility and stability in your deployments.

---

## 2: Liveness Probe for Each Container

A **liveness probe** is a Kubernetes best practice used to check whether the application inside a running pod is actually healthy. While Kubernetes can detect and restart failed pods, it doesn't automatically restart pods where the container is unresponsive or stuck, even if the pod appears "healthy." A liveness probe solves this by regularly executing a small script or command (e.g., every 5 seconds) to verify that the application is responsive. If the check fails, Kubernetes restarts the pod.

In this case, developers included a utility (`/bin/grpc_health_probe`) in each microservice image to perform this check. This can be configured using the `exec` command in the `livenessProbe` section of each container, adjusting the target address and port per service.

### Configuration Options for Liveness Probe Health Checks

---

### 1: Command Execution

If the developer configures the liveness probe using a small program, then we'll do the following configurations:

```yaml
livenessProbe:
  periodSeconds: 5
  exec:
    command: ["/bin/grpc_health_probe", "-addr=:8080"]
````

> `/bin/grpc_health_probe` is basically the script inside the container provided by the developer

---

### 2: TCP Socket

If the developer configures the liveness probe to be configured using a TCP socket, then we'll do the following configurations:

```yaml
livenessProbe:
  initialDelaySeconds: 5
  periodSeconds: 5
  tcpSocket: 
    port: 6379
```

> `6379` is the port at which application is running
> `initialDelaySeconds: 5` — say we know the application takes 5 seconds to start, that's why we configured it

---

### 3: HTTP Probe / HTTP Endpoint

If the developer configured the application with an HTTP health check endpoint/path, then we can configure the liveness probe using application HTTP endpoints:

```yaml
livenessProbe:
  initialDelaySeconds: 5
  periodSeconds: 5
  httpGet:
    path: /health 
    port: 6379
```

---

## 3: Readiness Probe for Each Container

A **readiness probe** is a Kubernetes best practice used to signal when a container's application is fully initialized and ready to receive traffic. While a liveness probe detects if an app is still running, the readiness probe prevents traffic from reaching a pod **before** the app is fully started. Without it, requests may fail during the startup phase.

Readiness probes are configured similarly to liveness probes (e.g., checking every 5 seconds), and should be added to each container, with port numbers adjusted as needed for each microservice.

### Configuration Options for Readiness Probe Health Checks

---

### 1: Command Execution

```yaml
readinessProbe: 
  periodSeconds: 5
  exec:
    command: ["/bin/grpc_health_probe", "-addr=:8080"]
```

> `/bin/grpc_health_probe` is basically the script inside the container provided by the developer

---

### 2: TCP Socket

```yaml
readinessProbe: 
  initialDelaySeconds: 5
  periodSeconds: 5
  tcpSocket: 
    port: 6379
```

> `6379` is the port at which application is running
> `initialDelaySeconds: 5` — say we know the application takes 5 seconds to start, that's why we configured it

---

### 3: HTTP Probe / HTTP Endpoint

```yaml
readinessProbe: 
  initialDelaySeconds: 5
  periodSeconds: 5
  httpGet:
    path: /health 
    port: 6379
```

---

## 4: Resource Requests for Each Container

Defining **resource requests** for each container is a Kubernetes best practice to ensure the application gets enough CPU and memory when starting. These settings are added under the `resources` section in the container spec, at the same level as probes.

For typical applications without special needs, standard request values are around **100m CPU** and **64Mi memory**.

```yaml
resources:
  requests:
    cpu: 100m
    memory: 64Mi
```

---

## 5: Resource Limits for Each Container

In addition to **resource requests**, Kubernetes best practice includes defining **resource limits** to prevent a container from overconsuming CPU or memory and affecting other pods on the same node. Limits cap how much a container can use beyond its requested baseline.

```yaml
resources:
  limits:
    cpu: 200m
    memory: 128Mi
```

---

## 6: Don't Expose the NodePort

Using the **NodePort** service type to expose applications externally is considered a **bad practice** because it opens a specific port on **every worker node**, increasing the **security risk**.

Better approaches:

* Use the **LoadBalancer** service type
* Or use an **Ingress Controller**

These funnel external traffic through a single, controlled access point, improving **security** and **manageability**.

---

## 7: More Than 1 Replica for Deployment (At Least 2)

If you don't explicitly define the number of **replicas**, Kubernetes defaults to **one**. A single pod creates a **risk of service downtime** if it crashes.

To ensure **high availability**, configure at least **two or more replicas**:

```yaml
replicas: 2
```

---

## 8: More Than 1 Worker Node in Your Cluster

Running your cluster with **more than one worker node** avoids a **single point of failure**. If one node crashes, others continue serving traffic.

Combining this with multiple pod replicas greatly enhances **resilience and availability**, even in small clusters.

---

## 9: Labeling All Your K8s Components

Use **labels** consistently across all resources (pods, services, deployments). Labels are **key-value pairs** used to identify and organize resources.

Example:

```yaml
metadata:
  labels:
    app: my-app
    env: production
```

This improves **visibility**, **automation**, and **maintainability**.

---

## 10: Using Namespaces to Isolate K8s Resources

Use **namespaces** to isolate and organize resources. This:

* Groups apps logically
* Enables team-based access via **RoleBindings**
* Supports better security and management

You can group related services in one namespace or assign each service its own namespace.

---

## 11: Scan Images for Security Vulnerabilities

Use tools like **Trivy** for vulnerability scanning:

### Pre-deployment:

```bash
trivy image your-image-name:tag
```

### Post-deployment:

```bash
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].image}'
trivy image <image-name>
```

### Cluster-wide:

Install **Trivy Operator** to automatically scan running workloads and generate `VulnerabilityReports`.

---

## 12: No Root Access for Containers

Run containers **without root access** to reduce the risk of system-wide compromise.

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
```

Running as a non-root user enforces the **principle of least privilege** and improves security for multi-tenant environments.

---
