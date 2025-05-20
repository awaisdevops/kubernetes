# Create AWS EKS Cluster from UI

In this guide, we'll learn how to create an AWS EKS cluster from AWS Management Console. I detailed all the important steps for creating the cluster. You can follow the steps as is to provision the AWS EKS cluster.

---

## Project Summary

In this project, we'll learn how to manually set up an Amazon EKS cluster using the AWS Management Console. It involves creating IAM roles for EKS and EC2 to manage permissions, setting up a VPC for the worker nodes, and creating the EKS cluster with master nodes managed by AWS. After connecting to the cluster via `kubectl`, a node group of EC2 instances is created and attached as worker nodes. Auto scaling is then configured to adjust the number of worker nodes based on resource demands, and finally, you can deploy your application into the provisioned cluster.

### Technologies Used
- Kubernetes
- AWS EKS

### Project Description
- Configure necessary IAM Roles
- Create VPC with Cloudformation Template for Worker Nodes
- Create EKS cluster (Control Plane Nodes)
- Create Node Group for Worker Nodes and attach to EKS cluster
- Configure Auto-Scaling of worker nodes
- Deploy a sample application to EKS cluster

---

## Table of Contents

- Creating an IAM role for EKS to allow it to manage AWS resources.
- Creating a VPC where the worker nodes will run.
- Creating the EKS cluster, which includes master nodes managed by AWS.
- Connecting to the cluster using the kubectl command-line tool.
- Creating a second IAM role for EC2 to enable worker nodes to interact with AWS services.
- Creating a node group of EC2 instances to serve as worker nodes and attaching it to the cluster.
- Setting up auto scaling, so the number of worker nodes adjusts based on the cluster’s resource demands.

---

## 1. Create EKS IAM Role

We'll create a role named `eks-cluster-role` that will assign necessary permissions of other services to the EKS cluster to manage the K8s master node.

> IAM Console → Roles → Create role → Select "AWS service" → Choose "EKS" → Select "EKS - Cluster" → Next → Attach `AmazonEKSClusterPolicy` → Next → (Optional) Add tags → Next → Name the role (e.g., eks-cluster-role) → Create role

---

## 2. Create VPC for Worker Nodes

A default AWS VPC isn't suitable for EKS because EKS requires specific networking configurations. A custom VPC with properly configured subnets, firewall rules, and security groups ensures communication between the control plane and worker nodes.

We'll use AWS-provided CloudFormation template:

> CloudFormation Console → Create Stack → With new resources (standard) → Amazon S3 URL → Paste:  
> [https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-06-10/amazon-eks-vpc-private-subnets.yaml](https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-06-10/amazon-eks-vpc-private-subnets.yaml)  
> Follow the stack creation steps and wait for `CREATE_COMPLETE`.

---

## 3. Create EKS Cluster (Master Node)

> EKS Console → Create Cluster → Name: `eks-cluster-test` → Cluster IAM role: `eks-cluster-role`  
> Enable: “Allow cluster administrator access” → Authentication mode: **EKS API**  
> Networking: Select the VPC and subnets → Endpoint access: **Public and private**  
> Add-ons: Select **Amazon VPC CNI**, **kube-proxy**, **CoreDNS**, **Pod Identity Agent** → Create

---

## 4. Connect `kubectl` with EKS Cluster Locally

Even if we don't have any worker nodes running, we can connect to the EKS cluster using kubectl from our local machine. We create a kubeconfig file and check the connection with the following commands:
```sh
# make sure your aws configuration is set to the region of the EKS cluster
aws configure list
#       Name                    Value             Type    Location
#       ----                    -----             ----    --------
#    profile                <not set>             None    None
# access_key     ****************BDVT shared-credentials-file    
# secret_key     ****************eXn0 shared-credentials-file    
#     region             eu-central-1      config-file    ~/.aws/config

# make sure there is no old ~/.kube/config file
rm ~/.kube/config
# or
mv ~/.kube/config ~/.kube/config_backup

# now create a new ~/.kube/config file
aws eks update-kubeconfig --name eks-cluster-test
# Added new context arn:aws:eks:eu-central-1:369076538622:cluster/eks-cluster-test to ~/.kube/config

# check the connection
kubectl cluster-info
# Kubernetes control plane is running at https://73A57A23BA7BAAE56115E5F68C988976.gr7.eu-central-1.eks.amazonaws.com
# CoreDNS is running at https://73A57A23BA7BAAE56115E5F68C988976.gr7.eu-central-1.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

---

## 5. Create EC2 IAM Role for Node Group

To enable communication between EC2 worker nodes and AWS/Kubernetes services:

> IAM Console → Roles → Create role → Trusted entity type: "AWS service" → Use case: **EC2**
> Attach policies: `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`
> Name: `eks-node-group-role` → Create role

---

## 6. Create Node Group and Attach to EKS Cluster

> EKS Console → Cluster → Compute → Add Node Group
> Name: `eks-node-group` → IAM Role: `eks-node-group-role`
> Instance type: `t3.small` → Configure scaling, subnets → Review → Create node group

---

## 7. Configure Auto-Scaling

EKS creates an **Auto Scaling Group (ASG)** with each node group. While the ASG sets EC2 instance bounds, actual scaling is handled by Kubernetes **Cluster Autoscaler**.

---

### a. Auto Scaling Group (Already Created)

Node groups automatically create an ASG. You can manually adjust min/max instance limits.

---

### b. Create a Custom IAM Policy and Attach It to Node Group Role

I. Go to IAM → Policies → Create Policy → JSON tab:

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "autoscaling:DescribeAutoScalingGroups",
                   "autoscaling:DescribeAutoScalingInstances",
                   "autoscaling:DescribeLaunchConfigurations",
                   "autoscaling:DescribeTags",
                   "autoscaling:SetDesiredCapacity",
                   "autoscaling:TerminateInstanceInAutoScalingGroup",
                   "ec2:DescribeLaunchTemplateVersions"
               ],
               "Resource": "*"
           }
       ]
   }
   ```

II. Name: `node-group-autoscale-policy`

III. Attach this policy to the role `eks-node-group-role`

---

### c. Configure Tags on the Auto Scaling Group

Tags allow Kubernetes Cluster Autoscaler to detect the ASG:

* `k8s.io/cluster-autoscaler/eks-cluster-test`
* `k8s.io/cluster-autoscaler/enabled`

These are automatically added—no manual configuration is required.

---

## Deploy Cluster Autoscaler

a. **Deploy**:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
   ```

   > Change the image tag from `v1.31.2` to `v1.31.1` before/after applying.

b. **Verify Deployment**:

   ```bash
   kubectl get deployment -n kube-system cluster-autoscaler
   ```

c. **Edit Deployment**:

   ```bash
   kubectl edit deployment -n kube-system cluster-autoscaler
   ```

   * Add after line 9:

     ```yaml
     cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
     ```
   * Replace `<CLUSTER NAME>` with `eks-cluster-test`
   * Add:

     ```yaml
     - --balance-similar-node-groups
     - --skip-nodes-with-system-pods=false
     ```
   * Update the image tag with correct K8s version

d. **Verify Running Pod**:

   ```bash
   kubectl get pods -n kube-system
   ```

e. **Check Node**:

   ```bash
   kubectl get pod <autoscaler-pod-name> -n kube-system -o wide
   ```

f. **View Logs**:

   ```bash
   kubectl logs -n kube-system <autoscaler-pod-name>
   kubectl logs -n kube-system <autoscaler-pod-name> > auto-scalar-logs.txt
   ```

   > Open `auto-scalar-logs.txt` in VS Code for detailed analysis

---

## License

This project is licensed under the [MIT License](LICENSE).
