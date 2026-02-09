# Student DevOps Project - EKS Architecture

This is a complete CI/CD pipeline that automates the deployment process from building Docker images to running them on an AWS EKS cluster.

## Architecture Overview

```
EC2 (with Jenkins, Docker, Terraform, kubectl)
    ↓
1. Build Backend & Frontend Docker images
    ↓
2. Push images to Docker Hub
    ↓
3. Create EKS cluster using Terraform
    ↓
4. Deploy images to EKS cluster
    ↓
AWS EKS Cluster (with 2+ worker nodes)
```

## Prerequisites

You have already installed on EC2:
- Jenkins
- Docker
- Terraform
- kubectl
- AWS CLI (configured with credentials)

## Project Structure

```
.
├── backend/                      # Backend application
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── frontend/                     # Frontend application
│   ├── Dockerfile
│   ├── package.json
│   ├── public/
│   └── src/
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                   # EKS cluster, VPC, subnets, security groups
│   ├── variables.tf              # Terraform variables with defaults
│   └── terraform.tfstate         # Generated after first apply
├── k8s/                          # Kubernetes manifests
│   ├── backend-deployment.yaml   # Backend deployment with service
│   ├── frontend-deployment.yaml  # Frontend deployment with service
│   ├── backend-service.yaml      # Optional: separate service definition
│   └── frontend-service.yaml     # Optional: separate service definition
├── Jenkinsfile                   # CI/CD pipeline
└── README.md                      # This file
```

## Required Configuration

Before running the pipeline, update these values:

### 1. Jenkinsfile
```groovy
DOCKER_USER = "naveen656"           # Your Docker Hub username
AWS_ACCOUNT_ID = "YOUR_AWS_ACCOUNT_ID"  # Your AWS Account ID
```

### 2. AWS Credentials in Jenkins
Create two Jenkins credentials:
- **aws-credentials**: AWS Access Key ID & Secret Access Key
- **dockerhub-creds**: Docker Hub username & password

### 3. Terraform Variables (optional)
Edit `terraform/variables.tf` to customize:
- AWS region (default: us-east-1)
- VPC CIDR blocks
- Node count (default: 2)
- Instance types (default: t3.medium)

## Pipeline Stages

### 1. Checkout
Pulls the latest code from git repository

### 2. Docker Login
Authenticates with Docker Hub using credentials

### 3. Build Backend Image
Builds Docker image from `backend/Dockerfile`

### 4. Build Frontend Image
Builds Docker image from `frontend/Dockerfile`

### 5. Push Images to Docker Hub
Pushes images with tags:
- `naveen656/student-backend:latest`
- `naveen656/student-backend:v1.0`
- `naveen656/student-frontend:latest`
- `naveen656/student-frontend:v1.0`

### 6. Create EKS Cluster
Uses Terraform to create:
- VPC with public and private subnets
- Internet Gateway & NAT Gateway
- EKS Control Plane
- 2 EKS Worker Nodes (t3.medium)
- Security groups and IAM roles

**Note**: This stage takes 10-15 minutes the first time. Subsequent runs will update the cluster.

### 7. Configure kubectl
Sets up kubeconfig to access the EKS cluster

### 8. Deploy to EKS
Applies Kubernetes manifests:
- Creates `student-app` namespace
- Deploys backend pods (2 replicas)
- Deploys frontend pods (2 replicas)
- Creates services (backend: ClusterIP, frontend: LoadBalancer)
- Sets up Horizontal Pod Autoscalers (HPA)

## What Gets Deployed to EKS

### Backend
- **Image**: naveen656/student-backend:latest
- **Replicas**: 2 (autoscales up to 5)
- **Service**: ClusterIP on port 5000
- **Port**: 5000
- **Health Checks**: Liveness & Readiness probes
- **Resources**: 250m CPU & 256Mi memory requested

### Frontend
- **Image**: naveen656/student-frontend:latest
- **Replicas**: 2 (autoscales up to 5)
- **Service**: LoadBalancer on port 80
- **Port**: 80
- **Health Checks**: Liveness & Readiness probes
- **Resources**: 250m CPU & 256Mi memory requested

## Accessing the Application

After deployment completes, get the frontend external IP:

```bash
kubectl get svc -n student-app
```

Look for the `EXTERNAL-IP` of `frontend-service` and access it in your browser.

## Cost Estimation

- EKS Cluster: ~$0.10/hour
- 2x t3.medium nodes: ~$0.04/hour each
- Data transfer and storage: varies

**Total: ~$75/month (without optimization)**

## Terraform State Management

After the first run, a `terraform.tfstate` file is created. Keep this safe! It contains your infrastructure state.

To destroy all AWS resources:
```bash
cd terraform
terraform destroy
```

## Monitoring & Logs

### View pod logs:
```bash
kubectl logs -n student-app pod/student-backend-xxxxx
kubectl logs -n student-app pod/student-frontend-xxxxx
```

### View cluster info:
```bash
kubectl get all -n student-app
kubectl describe deployment student-backend -n student-app
```

### Monitor HPA status:
```bash
kubectl get hpa -n student-app
```

## Troubleshooting

### ImagePullBackOff errors
- Ensure Docker Hub images exist
- Check image names match in deployment

### EKS cluster creation hangs
- Check AWS credentials
- Ensure IAM user has permissions
- Check AWS service quotas

### kubectl connection refused
- Run: `aws eks update-kubeconfig --region us-east-1 --name student-eks`
- Verify AWS credentials are set

### Pods not starting
- Check resources: `kubectl describe pod <pod-name> -n student-app`
- View logs: `kubectl logs <pod-name> -n student-app`

## Cleanup

To stop charges from AWS:

```bash
# Destroy EKS cluster and all resources
cd terraform
terraform destroy

# Remove kubeconfig entry
kubectl config delete-context arn:aws:eks:us-east-1:ACCOUNT_ID:cluster/student-eks
```

## Next Steps

1. Implement CI/CD improvements (unit tests, code scanning)
2. Set up monitoring (CloudWatch, Prometheus)
3. Implement backup and disaster recovery
4. Set up certificate management (TLS/SSL)
5. Implement ingress controller for routing

## Support

For issues, check:
1. Jenkins logs in Jenkins UI
2. Terraform state and logs
3. EKS cluster events: `kubectl get events -n student-app`
4. AWS CloudFormation stack events (EKS uses CloudFormation)
