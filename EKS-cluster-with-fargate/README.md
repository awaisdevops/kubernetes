# Create AWS EKS Cluster with Fargate

In this project, I’ve demonstrated how to setup an Amazon EKS cluster AWS Fargate. While node groups use EC2 instances managed within your AWS account, Fargate offers a serverless approach to deploying containers, where AWS provisions and manages the underlying infrastructure automatically. Each pod in Fargate gets its own virtual machine, unlike EC2 nodes which can host multiple pods. However, Fargate comes with some limitations—it does not support stateful workloads or daemon sets. For flexibility, both EC2 node groups and Fargate profiles can be attached to the same EKS cluster, enabling hybrid deployment strategies.

### Technologies Used
- Kubernetes
- AWS EKS
- AWS Fargate

### Project Description
- Create Fargate IAM Role
- Create Fargate Profile
- Deploy an example application to EKS cluster using Fargate profile
---

## Table of content:

- Creating an IAM role for EKS to allow it to manage AWS resources.
- Creating a VPC where the worker nodes will run.
- Creating the EKS cluster.
- Connecting to the cluster using the kubectl command-line tool.
- Creating a second IAM role for Fargate to enable EC2 to interact with AWS services.
- Create Fargate Profile.

---

### 1: Create EKS IAM Role:
We'll create a role named "eks-cluster-role" that will assign necessary permissions to other services to the EKS cluster to manage the K8s master node.

**Steps:**
1. Open the IAM Console > Roles > Create role > Select "AWS service" > Choose "EKS" > Select "EKS - Cluster" > Next.
2. Attach "AmazonEKSClusterPolicy" > Next > (Optional) Add tags > Next > Name the role (e.g., eks-cluster-role) > Create role.

---

### 2: Create VPC for Worker Nodes:
A default AWS VPC isn't suitable for EKS because EKS requires specific networking configurations to support Kubernetes communication between AWS-managed master nodes and user-managed worker nodes. A custom VPC with properly configured public/private subnets, firewall rules, and security groups ensures this communication, allows services like load balancers to work correctly, and enables EKS to manage network settings via IAM roles.

We'll create the VPC for node group worker node with the AWS suggested configurations using CloudFormation.

**Steps:**
1. Open CloudFormation Console > Create Stack > With new resources (standard) > Choose "Amazon S3 URL" > Paste template URL (e.g., [Amazon EKS VPC Template](https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-06-10/amazon-eks-vpc-private-subnets.yaml)).
2. Next > Enter stack name and parameters > Next > (Optional) configure stack options > Next > Review settings > Acknowledge IAM changes > Create stack.
3. Wait for the status to become CREATE_COMPLETE.

---

### 3: Create EKS Cluster (Master Node):
Here is the complete single-line guide to **create an EKS Cluster** based on your specifications:

**Steps:**
1. Open EKS Console > Create Cluster > Cluster configuration > Enter name `eks-cluster-test` > Choose Cluster IAM role `eks-cluster-role`.
2. Enable "Allow cluster administrator access" > Set Cluster authentication mode to **EKS API** > Under Networking, select the VPC and subnets created for EKS worker nodes.
3. Set Cluster endpoint access to **Public and private** > In Amazon EKS add-ons, select **Amazon VPC CNI**, **kube-proxy**, **CoreDNS**, and **Amazon EKS Pod Identity Agent** > Click **Create** to launch the cluster.

---

### 4: Connect kubectl with EKS Cluster Locally:
Now that the cluster is created, we can configure `kubectl` on our local machine to connect to it; even without worker nodes, communication with the API server is possible because the control plane is active.

**Steps:**
```bash
aws configure list #checking our default region
aws eks update-kubeconfig --name eks-cluster-test
aws eks update-kubeconfig --name <eks-cluster-name> #creating a kube config file for connecting kubectl with eks cluster
#file location ~/.kube/config. this file contains connection information for eks cluster to connect.
kubectl cluster-info #getting cluster info
````

---

### 5: Create IAM Role for Fargate:

Before creating a Fargate profile in EKS, you need to create a dedicated IAM role for Fargate. Similar to roles used by the EKS control plane or EC2 worker nodes, this role grants Fargate the necessary permissions to run pods and interact with AWS resources securely on your behalf.

**Steps:**

1. IAM → Role → Create Role → Trusted entity type (AWS service) → Service (EKS) → Use case (EKS - Fargate pod) → Permissions policies (AmazonEKSFargatePodExecutionRolePolicy) → Role name (eks-fargate-role) → Create role.

---

### 6: Create Fargate Profile:

Fargate Profile in Amazon EKS allows you to specify which pods should run on AWS Fargate by mapping Kubernetes namespaces and optional labels. This enables EKS to automatically launch those pods on serverless infrastructure managed by AWS, eliminating the need to manage EC2 instances for those workloads.

To create a Fargate profile from the AWS Management Console, follow these steps:

1. **EKS Console** -->> **Fargate Profiles** -->> **Create Fargate Profile** -->> **Profile Configuration** -->> **Name** -->> dev-profile -->> **Pod Execution Role** -->> eks-fargate-role -->> **Selectors** -->> Specify namespaces and optional labels for the pods to run on Fargate -->> **Create**.

When deploying pods on Fargate, namespaces and matching labels are crucial both in the Fargate policy and in the YAML configuration file.

Additionally, in the Subnet section of the Fargate profile configuration, select subnets from your own VPC. Although Fargate provisions EC2 instances in the AWS account, networking will be handled through your VPC. Public subnets should be excluded, as Fargate ensures all instances remain private.

#### Steps to deploy an example application to EKS cluster using Fargate profile
If we want our nginx Pods to be scheduled by Fargate, we have to add the namespace and label specified in the Pod selection rule to its K8s deployment configuration file. Create a new `nginx-deployment.yaml` file with the following content:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: dev # <---
spec:
  selector:
    matchLabels:
      app: nginx
      profile: fargate # <---
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
        profile: fargate # <---
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

Now execute the following commands:

```sh
# create the namespace
kubectl create namespace dev

# apply the deployment configuration
kubectl apply -f nginx-deployment.yaml

# check the pod is running
kubectl get pods -n dev -w
# NAME                     READY   STATUS              RESTARTS   AGE
# nginx-7f5bb7bcc5-x5bwh   0/1     Pending             0          7s
# nginx-7f5bb7bcc5-x5bwh   0/1     Pending             0          35s
# nginx-7f5bb7bcc5-x5bwh   0/1     ContainerCreating   0          36s
# nginx-7f5bb7bcc5-x5bwh   1/1     Running             0          43s
```

The pod was pending for 35 seconds because Fargate creates a virtual machine for each pod, which takes some time.

Now let's see the nodes:
```sh
kubectl get nodes
# NAME                                                       STATUS   ROLES    AGE     VERSION
# fargate-ip-192-168-164-158.eu-central-1.compute.internal   Ready    <none>   2m57s   v1.26.3-eks-f4dc2c0
# ip-192-168-222-24.eu-central-1.compute.internal            Ready    <none>   3d4h    v1.26.2-eks-a59e1f0
```

The first node is the newly created virtual machine. We don't see it in our AWS account. But still it got an IP address from the range of a subnet in our VPC. The second one is the EC2 instance created by the node group in demo project #1. We can see this instance in our AWS account.

---

## License

MIT License - See LICENSE file for details.
