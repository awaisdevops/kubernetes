# Automating AWS EKS Cluster Creation with eksctl

Manually creating an EKS cluster with roles, VPCs, and configurations is time-consuming and hard to replicate. To simplify this, eksctl is a command-line tool that automates cluster creation. It handles roles, VPCs, and configurations in the background, allowing customization with options like Kubernetes version, region, and node types. Using eksctl eliminates the need for manual setup, making the process more efficient with a single command.

### Technologies Used
- Kubernetes
- AWS EKS
- eksctl
- Linux

### Project Description
- Create EKS cluster using eksctl tool that reduces the manual effort of creating an EKS cluster

---

## EKS Cluster Creation Options

You have two options for creating an EKS cluster:

1. **Using `eksctl` Command-Line Tool**: Pass the required configuration values directly as parameters.
2. **Using a YAML Config File**: Define your cluster configurations in a YAML file and pass it to the `eksctl` tool.

Both methods allow you to create an EKS cluster efficiently with customized settings.

---

## Install eksctl tool in Ubuntu 22.04

```bash
sudo apt update # Update package list
sudo apt install -y curl wget apt-transport-https # Install necessary dependencies
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/v0.135.0/eksctl_Linux_amd64.tar.gz" -o /tmp/eksctl.tar.gz # Download the latest eksctl release
tar -xvzf /tmp/eksctl.tar.gz -C /tmp # Extract the tarball
sudo mv /tmp/eksctl /usr/local/bin # Move eksctl binary to /usr/local/bin
eksctl version # Verify the installation
````

---

## Creating AWS EKS Cluster using eksctl Tool

We are creating a fully managed Amazon EKS cluster with both EC2-based node groups and Fargate support. It sets up the cluster in a specified region with a given Kubernetes version, provisions a managed node group using `t3.medium` instances (2 desired nodes, min 1, max 3), enables private networking, configures VPC subnets, and sets up optional SSH access with a specified public key. Fargate is enabled to run serverless pods.

```bash
eksctl create cluster \  
--name <cluster-name> \                         # Name of the EKS cluster  
--region <aws-region> \                         # AWS region where the cluster will be created  
--version <eks-version> \                       # Kubernetes version to use  
--nodegroup-name <nodegroup-name> \             # Name of the node group  
--node-type t3.medium \                         # EC2 instance type for worker nodes  
--nodes 2 \                                     # Desired number of nodes  
--nodes-min 1 \                                 # Minimum number of nodes  
--nodes-max 3 \                                 # Maximum number of nodes  
--node-volume-size 50 \                         # EBS volume size in GiB for each node  
--node-private-networking \                     # Enable private networking for nodes  
--fargate \                                     # Enable Fargate for serverless pods  
--vpc-private-subnets=<private-subnet-1>,<private-subnet-2> \  # Private subnet IDs for the VPC  
--vpc-public-subnets=<public-subnet-1>,<public-subnet-2> \     # Public subnet IDs for the VPC  
--managed \                                     # Use managed node group  
--ssh-access \                                  # Enable SSH access to the nodes  
--ssh-public-key <key-name> \                   # Name of the existing EC2 SSH key pair  
--verbose                                       # Enable verbose output for detailed logs

```

---

## Creating AWS EKS Cluster using Config File

### -->> vim eks-cluster.yaml

```yaml
# EKS cluster configuration file for eksctl
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: my-eks-cluster          # Name of the EKS cluster
  region: us-west-2             # AWS region where the cluster will be deployed

# Configuration for EC2-based node group
nodeGroups:
  - name: eks-node-group        # Name of the node group
    instanceType: t3.medium     # EC2 instance type for the nodes
    desiredCapacity: 2          # Number of nodes to start with
    minSize: 1                  # Minimum number of nodes in the group
    maxSize: 3                  # Maximum number of nodes in the group
    volumeSize: 50              # EBS volume size in GiB for each node
    volumeType: gp2             # Volume type
    ssh:
      publicKeyName: eks-key    # Name of the existing EC2 key pair for SSH access
    labels:
      app: web-app              # Labels applied to the nodes
    taints:
      - effect: NoSchedule      # Taint effect (NoSchedule prevents non-tolerating pods from running)
        key: dedicated
        value: fargate          # Taint value to restrict usage to certain pods

# Configuration for AWS Fargate profile
fargateProfiles:
  - name: fargate-profile       # Name of the Fargate profile
    selectors:
      - namespace: default      # Namespace whose pods should run on Fargate
      - labels:
          app: web-app          # Label selector to run matching pods on Fargate

# EKS managed add-ons to install
addons:
  - name: vpc-cni               # Amazon VPC CNI plugin for networking
    version: latest             # Use the latest version
  - name: kube-proxy            # Kube-proxy for networking
  - name: coreDNS               # CoreDNS for service discovery

# IAM configuration
iam:
  serviceRole: arn:aws:iam::<account-id>:role/eks-cluster-role  # IAM role ARN for the EKS control plane

# VPC configuration
vpc:
  cidr: 192.168.0.0/16           # Custom CIDR block for the VPC
  subnets:
    private:
      - cidr: 192.168.1.0/24     # Private subnet CIDR
    public:
      - cidr: 192.168.2.0/24     # Public subnet CIDR
```
### Create the cluster using the configuration file with the eksctl tool.

```bash
eksctl create cluster -f eks-cluster.yaml

# 2023-05-18 15:36:18 [ℹ]  eksctl version 0.141.0
# 2023-05-18 15:36:18 [ℹ]  using region eu-central-1
# 2023-05-18 15:36:18 [ℹ]  setting availability zones to [eu-central-1c eu-central-1b eu-central-1a]
# 2023-05-18 15:36:18 [ℹ]  subnets for eu-central-1c - public:192.168.0.0/19 private:192.168.96.0/19
# 2023-05-18 15:36:18 [ℹ]  subnets for eu-central-1b - public:192.168.32.0/19 private:192.168.128.0/19
# 2023-05-18 15:36:18 [ℹ]  subnets for eu-central-1a - public:192.168.64.0/19 private:192.168.160.0/19
# 2023-05-18 15:36:18 [ℹ]  nodegroup "demo-nodes" will use "" [AmazonLinux2/1.26]
# 2023-05-18 15:36:18 [ℹ]  using Kubernetes version 1.26
# 2023-05-18 15:36:18 [ℹ]  creating EKS cluster "demo-cluster" in "eu-central-1" region with managed nodes
# 2023-05-18 15:36:18 [ℹ]  will create 2 separate CloudFormation stacks for cluster itself and the initial managed nodegroup
# 2023-05-18 15:36:18 [ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=eu-central-1 --cluster=demo-cluster'
# 2023-05-18 15:36:18 [ℹ]  Kubernetes API endpoint access will use default of {publicAccess=true, privateAccess=false} for cluster "demo-cluster" in "eu-central-1"
# 2023-05-18 15:36:18 [ℹ]  CloudWatch logging will not be enabled for cluster "demo-cluster" in "eu-central-1"
# 2023-05-18 15:36:18 [ℹ]  you can enable it with 'eksctl utils update-cluster-logging --enable-types={SPECIFY-YOUR-LOG-TYPES-HERE (e.g. all)} --region=eu-central-1 --cluster=demo-cluster'
# 2023-05-18 15:36:18 [ℹ]  
# 2 sequential tasks: { create cluster control plane "demo-cluster", 
#     2 sequential sub-tasks: { 
#         wait for control plane to become ready,
#         create managed nodegroup "demo-nodes",
#     } 
# }
# 2023-05-18 15:36:18 [ℹ]  building cluster stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:36:19 [ℹ]  deploying stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:36:49 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:37:19 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:38:19 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:39:20 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:40:20 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:41:20 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:42:20 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:43:20 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:44:21 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:45:21 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:46:21 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:47:21 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:48:21 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-cluster"
# 2023-05-18 15:50:23 [ℹ]  building managed nodegroup stack "eksctl-demo-cluster-nodegroup-demo-nodes"
# 2023-05-18 15:50:24 [ℹ]  deploying stack "eksctl-demo-cluster-nodegroup-demo-nodes"
# 2023-05-18 15:50:24 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-nodegroup-demo-nodes"
# 2023-05-18 15:50:54 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-nodegroup-demo-nodes"
# 2023-05-18 15:51:33 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-nodegroup-demo-nodes"
# 2023-05-18 15:53:07 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-nodegroup-demo-nodes"
# 2023-05-18 15:53:49 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-nodegroup-demo-nodes"
# 2023-05-18 15:54:29 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-nodegroup-demo-nodes"
# 2023-05-18 15:55:53 [ℹ]  waiting for CloudFormation stack "eksctl-demo-cluster-nodegroup-demo-nodes"
# 2023-05-18 15:55:53 [ℹ]  waiting for the control plane to become ready
# 2023-05-18 15:55:54 [✔]  saved kubeconfig as "/Users/fsiegrist/.kube/config"
# 2023-05-18 15:55:54 [ℹ]  no tasks
# 2023-05-18 15:55:54 [✔]  all EKS cluster resources for "demo-cluster" have been created
# 2023-05-18 15:55:54 [ℹ]  nodegroup "demo-nodes" has 2 node(s)
# 2023-05-18 15:55:54 [ℹ]  node "ip-192-168-48-96.eu-central-1.compute.internal" is ready
# 2023-05-18 15:55:54 [ℹ]  node "ip-192-168-64-248.eu-central-1.compute.internal" is ready
# 2023-05-18 15:55:54 [ℹ]  waiting for at least 1 node(s) to become ready in "demo-nodes"
# 2023-05-18 15:55:54 [ℹ]  nodegroup "demo-nodes" has 2 node(s)
# 2023-05-18 15:55:54 [ℹ]  node "ip-192-168-48-96.eu-central-1.compute.internal" is ready
# 2023-05-18 15:55:54 [ℹ]  node "ip-192-168-64-248.eu-central-1.compute.internal" is ready
# 2023-05-18 15:55:55 [ℹ]  kubectl command should work with "/Users/fsiegrist/.kube/config", try 'kubectl get nodes'
# 2023-05-18 15:55:55 [✔]  EKS cluster "demo-cluster" in "eu-central-1" region is ready

```

After nearly 20 minutes the cluster is ready. Kubectl was automatically configured to connect to the new cluster. The configuration is stored in `~/.kube/config`.

Let's review the created cluster now. 

```sh
eksctl get clusters
# NAME	        REGION        EKSCTL CREATED
# demo-cluster  eu-central-1  True

kubectl get nodes
# NAME                                              STATUS   ROLES    AGE     VERSION
# ip-192-168-48-96.eu-central-1.compute.internal    Ready    <none>   6m12s   v1.26.2-eks-a59e1f0
# ip-192-168-64-248.eu-central-1.compute.internal   Ready    <none>   6m11s   v1.26.2-eks-a59e1f0

aws iam list-roles --query "Roles[].RoleName"
# [
#     "AWSServiceRoleForAmazonEKS",
#     "AWSServiceRoleForAmazonEKSNodegroup",
#     "AWSServiceRoleForAutoScaling",
#     "AWSServiceRoleForSupport",
#     "AWSServiceRoleForTrustedAdvisor",
#     "eksctl-demo-cluster-cluster-ServiceRole-E4TVKLGKTBIZ",
#     "eksctl-demo-cluster-nodegroup-dem-NodeInstanceRole-KJW6DGERTROS"
# ]
```
---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.
