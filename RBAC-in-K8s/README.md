# Authentication and Authorization in Kubernetes (RBAC)

In this guide, we'll see how authentication and authorization work in Kubernetes using RBAC (Role Based Access Control) mechanism. We'll configure users, groups, and their permissions within a cluster. We'll configure the Kubernetes resources like:
1. **Role**, **RoleBinding** for granting namespaced permissions to developers
2. **ClusterRole**, **ClusterRoleBinding** for granting permissions to Kubernetes admins
3. **Service Accounts** for services

---

## Why Manage Permissions in Kubernetes?

Managing permissions in a Kubernetes cluster is essential to ensure the right level of access for different users. Administrators require full access to manage the cluster, while developers should have limited permissions to prevent accidental disruptions. Following the security best practice of "least privilege," each user is granted only the minimum permissions necessary to perform their tasks.

---

## Role and RoleBinding: Defining Permissions for Developers

In a Kubernetes cluster with multiple namespaces, each developer team typically deploys applications in their own namespace. To ensure teams only access their designated namespaces and avoid impacting others, Kubernetes uses Role-Based Access Control (RBAC).

- **Role**: Defines permissions (like read, create, edit, delete) for specific resources (pods, deployments, services, secrets, etc.) within a namespace.
- **RoleBinding**: Connects a Role to a user or a group of users, granting the specified permissions.

Instead of binding permissions individually for each user, you can group users (e.g., a "dev-team" group) and bind the Role to the group, ensuring all members inherit the same access rights.

---

## Creating a Role and Binding it to a User

### 1. Define a Role

Create a file `role.yaml` and define the role as follows:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default  # Specify your desired namespace here
rules:
- apiGroups:
  - ""              # Core API group (for resources like pods)
  resources:
  - pods           # List of resources this role can access
  verbs:          # Actions that can be performed on the resources
  - get
  - list
  - watch
```

### 2. Apply the Role

```bash
kubectl apply -f role.yaml
```

### 3. Verify the Role Creation

```bash
kubectl get role
```

### 4. Create a RoleBinding

Create a file `rolebinding.yaml` for role binding:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default  # Specify the same namespace as the Role
subjects:
- kind: User  # Can be User, Group, or ServiceAccount
  name: jack  # Name of the user to bind
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader       # Name of the Role to bind to
  apiGroup: rbac.authorization.k8s.io
```

### 5. Apply the RoleBinding

```bash
kubectl apply -f rolebinding.yaml
```

### 6. Verify the RoleBinding

```bash
kubectl get rolebinding
```

### 7. Check User Permissions

Check if user `jack` has permissions for pods in the default namespace:

```bash
-->> kubectl auth can-i get pod --as jack
-->> kubectl auth can-i <permission-to-check> <upon-what-resource> --as <user-name>
#we didn't define any namespace here as we are hecking the permissions in the default namepace
#checking permissions privileged to the user
#yes 
#that means user jack has provided with get permission on pod in defined namespace
-->> kubectl auth can-i list  pod --as jack
#yes
-->> kubectl auth can-i update  pod --as jack
#no
-->> kubectl auth can-i delete  pod --as jack
#no
-->> kubectl auth can-i watch  pod --as jack
#yes
```

In short, a **pod-reader** Role is created in the **default namespace**, giving access to pods for tasks like viewing, listing, and watching them. Next, this role is assigned to the user **jack** through a **RoleBinding** in the same namespace. Afterward, a few commands are used to check if **jack** has the right permissions to perform various actions on the pods, like viewing and listing them. This approach helps implement **fine-grained access control** in Kubernetes, using **RBAC** to define roles and assign them to specific users, ensuring that access to resources is both secure and appropriately restricted.

---

## ClusterRole and ClusterRoleBinding: Defining Permissions for Kubernetes Administrators

Kubernetes administrators manage the entire cluster — across all namespaces — configuring volumes, resources, and performing cluster-wide operations. Since a regular Role is limited to a single namespace, administrators require cluster-wide permissions.

- **ClusterRole**: Defines permissions across the entire cluster (not restricted to a namespace).
- **ClusterRoleBinding**: Binds the ClusterRole to a user or group, granting them cluster-wide access.

Typically, you create an admin group and attach a ClusterRole to it using a ClusterRoleBinding, enabling full administrative capabilities across the cluster.

---

## Creating a ClusterRole and Binding it to a User Using ClusterRoleBinding

### 1. Define a ClusterRole

Create a file `clusterrole.yaml` for the cluster role definition:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:
- apiGroups:
  - ""                # Core API group for resources like pods
  resources:
  - secrets            # This clusterrole can only access resource secret
  verbs:            # Actions that can be performed on the resources
  - get
  - list
  - watch
```

### 2. Apply the ClusterRole

```bash
kubectl apply -f clusterrole.yaml
```

### 3. Verify the ClusterRole Creation

```bash
kubectl get clusterrole
```

### 4. Create a ClusterRoleBinding

Create a file `clusterrolebinding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: User
  name: johncena  # Specify the name of your user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader         # Specify the name of the ClusterRole to bind
  apiGroup: rbac.authorization.k8s.io
```

### 5. Apply the ClusterRoleBinding

```bash
kubectl apply -f clusterrolebinding.yaml
```

### 6. Verify the ClusterRoleBinding

```bash
kubectl get clusterrolebindings.rbac.authorization.k8s.io
```

### 7. Check User Permissions

Check if user `johncena` has permissions for secrets:

```bash
-->> kubectl auth can-i get secret --as johncena  -A
#A for all means checking the permissions of get upon secret for user kohncena.
-->> kubectl auth can-i watch secret --as johncena  -A
#yes
-->> kubectl auth can-i list secret --as johncena  -A
#yes
-->> kubectl auth can-i delete secret --as johncena  -A
#no that means user johncena is any of the namespaces doesn't ahve permissions to delete any secert
-->> kubectl auth can-i update secret --as johncena  -A
#no
```
In this setup, a **ClusterRole** called **secret-reader** is created to grant access to **secrets** for viewing, listing, and watching across the entire cluster. This role is then assigned to the user **johncena** using a **ClusterRoleBinding**. After applying the resources, commands are used to check if **johncena** has permissions to perform actions on secrets, such as viewing, listing, or deleting them. This approach ensures cluster-wide access control by defining a **ClusterRole** and binding it to a user with **ClusterRoleBinding**.

---

## Users and Groups in Kubernetes

Kubernetes does not natively manage users or groups. Instead, it provides an interface that allows you to integrate external sources for authentication and authorization.

External sources include:

- Static token files (containing usernames and tokens)
- Certificates (signed by Kubernetes or a third-party)
- Identity services (like LDAP, Active Directory)

The Kubernetes API Server handles authentication by consulting these configured external sources when users attempt to access the cluster.

To manage users and groups:

- Use a static token file and optionally define groups within it.
- Generate user certificates manually.
- Configure an external identity provider like LDAP.

Kubernetes delegates the management of users and groups to the administrator — it only verifies credentials based on configured sources.

---

## Service Accounts in Kubernetes

A **Service Account** is used by applications that need to connect to the Kubernetes cluster for tasks like resource creation or data retrieval. For example, Prometheus requires a Service Account to collect cluster metrics for monitoring.

Examples:

- Internal apps (e.g., Prometheus, RabbitMQ, Redis) require access to monitor other services.
- Microservices may need access only within their own namespace.
- External tools (e.g., Jenkins, Terraform) might deploy or configure resources inside the cluster.

When a request is made to the Kubernetes cluster, it first reaches the **KubeAPI Server**. The API server **authenticates** the request and then **authorizes** it to determine whether the requested action is allowed within the cluster.

To enable authentication for our monitoring application, we'll create a **Service Account** and a corresponding token. This token will authenticate the application.

For **authorization**, we’ll use **RBAC** by creating a role and binding it to the Service Account using a **RoleBinding**. This ensures the monitoring application can access the required resources within the cluster.

By default, Kubernetes assigns a **ServiceAccount** and token to each pod. This Service Account belongs to the default namespace. We can customize our pod's YAML manifest to specify a different Service Account if necessary, instead of using the default one.

## Creating Service Account:

To create a service account, run the following command:

```
kubectl create sa mysa
kubectl create sa <service-account-name>

kubectl get sa
#service account with name mysa is created
```

Once the service account is created, you can generate a token for it by running:

```
kubectl create token mysa
kubectl create token <service-account-name-for-which-token-is-being-created>
```

## Defining Permissions with Roles for Service Account:

To define roles for the service account, first create a `role.yaml` file with the following contents:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups:
  - ''
  resources:
  - pods
  verbs:
  - get
  - watch
  - list
```

Apply the role to the cluster using:

```
kubectl apply -f role.yaml
```

This will create the `pod-reader` role.

Next, create a `rolebinding.yaml` file to bind the role to the service account:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: mysa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Apply the role binding using:

```
kubectl apply -f rolebinding.yaml
```

This will bind the `pod-reader` role to the `mysa` service account.

## Attaching Service Account to a Pod:

To attach the service account to a pod, create a `pod.yaml` file with the following contents:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  serviceAccountName: mysa # this attribute is attaching the service account with our pod
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
```

Apply the pod manifest using:

```
kubectl apply -f pod.yaml
```

This will create the pod and associate the `mysa` service account with it.

To verify the pod's properties, use:

```
kubectl describe pod nginx
```

You should see the following output:

```
Service Account:  mysa (pod's been attached with our created sa 'mysa')
Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-76sxp (ro)
```

This shows that the service account's token is mounted inside the pod's container.

## Verifying Permissions:
---

To verify what actions the service account can perform, use the following commands:

Check if the service account can `get` pods:

```
kubectl auth can-i get pod --as=system:serviceaccount:default:mysa
```

Output: `yes` means the service account has the `get` permission.

Check if the service account can `update` pods:

```
kubectl auth can-i update pod --as=system:serviceaccount:default:mysa
```

Output: `no` means the service account does not have the `update` permission.

Check if the service account can `list` pods:

```
kubectl auth can-i list pod --as=system:serviceaccount:default:mysa
```

Output: `yes` means the service account has the `list` permission.

Check if the service account can `delete` pods:

```
kubectl auth can-i delete pod --as=system:serviceaccount:default:mysa
```

Output: `no` means the service account does not have the `delete` permission.
```

## Summary
---

In Kubernetes security, there are two main levels: authentication and authorization.

For example, when an application like Jenkins sends a request to the API server to create a new service in the default namespace, Kubernetes performs:

- **Authentication**: The API server verifies the identity of the user or application (Jenkins) to check if it is allowed to connect to the cluster. It confirms whether valid credentials (such as username/password or a certificate) are provided.
  
- **Authorization**: After successful authentication, Kubernetes checks what actions the authenticated user is allowed to perform. Using RBAC (Role-Based Access Control), Kubernetes examines the Roles or ClusterRoles assigned to the user to determine if they have permission for the requested operation.

In short, Kubernetes first verifies who you are, then checks what you are allowed to do.

---

## License
---

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
