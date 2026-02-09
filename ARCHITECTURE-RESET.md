# Architecture Reset Summary

This document outlines all changes made to implement the new EKS deployment architecture.

## Architecture Changed

**OLD**: EC2 → Docker Containers on EC2
**NEW**: Jenkins on EC2 → Build & Push to Docker Hub → Create EKS Cluster → Deploy to EKS

## Files Modified

### 1. Jenkinsfile
**Changes**:
- Added 8-stage pipeline (was 4 stages)
- Removed direct EC2 deployment
- Added EKS cluster creation using Terraform
- Added kubectl configuration
- Added Kubernetes deployment stage
- Added proper error handling and post-actions

**Stages**:
1. Checkout - Pull code
2. Docker Login - Auth with Docker Hub
3. Build Backend - Build Docker image
4. Build Frontend - Build Docker image  
5. Push Images - Push to Docker Hub
6. Create EKS Cluster - Run Terraform
7. Configure kubectl - Setup cluster access
8. Deploy to EKS - Apply K8s manifests

### 2. terraform/main.tf
**Old**: EC2 instance setup
**New**: Complete EKS cluster with:
- VPC with public/private subnets
- Internet Gateway & NAT Gateway
- EKS Control Plane
- 2 EKS Worker Nodes
- Security groups and IAM roles

### 3. terraform/variables.tf (NEW FILE)
**Contains**:
- AWS region configuration
- VPC CIDR blocks
- EKS cluster name and version
- Node group sizing (min 1, desired 2, max 4)
- Instance type (t3.medium)

### 4. terraform/outputs.tf (NEW FILE)
**Outputs**:
- EKS cluster endpoint
- VPC/Subnet IDs
- kubectl configuration command
- NAT Gateway IP

### 5. k8s/backend-deployment.yaml
**Changes**:
- Added namespace creation
- Added ConfigMap for environment variables
- Increased replicas: 1 → 2
- Added HPA (Horizontal Pod Autoscaler) - scales 2 to 5
- Added health checks (liveness & readiness probes)
- Increased resource requests
- Added security context

### 6. k8s/frontend-deployment.yaml
**Changes**:
- Added namespace creation
- Added ConfigMap for environment variables
- Increased replicas: 1 → 2
- Added HPA (Horizontal Pod Autoscaler) - scales 2 to 5
- Added health checks
- Increased resource requests
- Added security context

## New Files Created

| File | Purpose |
|------|---------|
| `terraform/variables.tf` | Terraform variables with defaults |
| `terraform/outputs.tf` | Terraform output values |
| `README-EKS.md` | Complete documentation |
| `DEPLOYMENT-GUIDE.md` | Step-by-step deployment instructions |
| `setup.sh` | Automated setup script |
| `validate.sh` | Configuration validation script |

## What You Need To Do

### 1. Update Jenkinsfile Values
```groovy
DOCKER_USER = "naveen656"           # Change to your Docker Hub username
AWS_ACCOUNT_ID = "YOUR_AWS_ACCOUNT_ID"  # Change to your AWS Account ID
```

### 2. Configure Jenkins Credentials
Go to Jenkins UI → Manage Jenkins → Manage Credentials → Add:

**aws-credentials** (AWS Credentials type):
- Access Key ID: `YOUR_AWS_ACCESS_KEY`
- Secret Access Key: `YOUR_AWS_SECRET_KEY`

**dockerhub-creds** (Username/Password type):
- Username: `your-docker-username`
- Password: `your-docker-password`

### 3. Verify Prerequisites on EC2
Run the validation script:
```bash
chmod +x validate.sh
./validate.sh
```

Required installed:
- ✓ Docker (running)
- ✓ Terraform
- ✓ kubectl
- ✓ AWS CLI (configured)
- ✓ Git

### 4. Initialize Terraform
```bash
cd terraform
terraform init
cd ..
```

### 5. (Optional) Customize Terraform
Edit `terraform/variables.tf` to change:
- AWS region
- VPC CIDR blocks
- Node count (default: 2)
- Instance types (default: t3.medium)

## Deployment Flow

```
┌─────────────────┐
│  Jenkins Job    │
└────────┬────────┘
         │
         ├─→ Checkout Code
         │
         ├─→ Docker Login
         │
         ├─→ Build Backend Image
         │
         ├─→ Build Frontend Image
         │
         ├─→ Push to Docker Hub
         │   (naveen656/student-backend:latest)
         │   (naveen656/student-frontend:latest)
         │
         ├─→ Terraform Create EKS (10-15 min first time)
         │   ├─ Create VPC
         │   ├─ Create EKS Control Plane
         │   ├─ Create 2 Worker Nodes
         │   └─ Setup Security/IAM
         │
         ├─→ Configure kubectl
         │
         ├─→ Deploy to EKS
         │   ├─ Create student-app namespace
         │   ├─ Deploy Backend (2 replicas, 2-5 with HPA)
         │   ├─ Deploy Frontend (2 replicas, 2-5 with HPA)
         │   └─ Create Services + HPA
         │
         └─→ Done! ✓
```

## Time Estimates

| Stage | Time |
|-------|------|
| Checkout | < 1 min |
| Docker operations | 5-10 min |
| Terraform (first) | 10-15 min |
| Terraform (subsequent) | < 1 min |
| Kubernetes deploy | 2-5 min |
| **Total (First Run)** | **20-40 min** |
| **Total (Subsequent)** | **10-20 min** |

## AWS Resources Created

### VPC
- CIDR: 10.0.0.0/16
- 2 Public Subnets (10.0.1.0/24, 10.0.2.0/24)
- 2 Private Subnets (10.0.11.0/24, 10.0.12.0/24)
- Internet Gateway
- NAT Gateway

### EKS
- Cluster Version: 1.29
- Control Plane Managed by AWS
- 2 Worker Nodes (t3.medium)
- Auto-scales from 1 to 4 nodes

### Security
- VPC Security Groups
- IAM Roles for Cluster & Nodes
- Network ACLs

## Cost Estimation

- EKS Cluster: ~$0.10/hour
- 2x t3.medium: ~$0.04/hour each
- NAT Gateway: ~$0.045/hour
- Data transfer: varies

**Estimated**: ~$100-150/month

## Accessing Your App

After deployment:
```bash
kubectl get svc -n student-app
```

Frontend external IP will appear. Access in browser.

## Cleanup

To avoid AWS charges:
```bash
cd terraform
terraform destroy
# Type 'yes' to confirm
```

This removes:
- EKS cluster
- VPC and all subnets
- NAT and Internet Gateways
- Security groups
- IAM roles

## Rollback Procedure

If deployment fails, options:

1. **Fix and retry**: 
   - Fix issue
   - Run Jenkins job again

2. **Rollback Kubernetes**:
   ```bash
   kubectl rollout undo deployment/student-backend -n student-app
   ```

3. **Destroy and restart**:
   ```bash
   terraform destroy
   # Then run Jenkins job again
   ```

## What Changed from Original

| Aspect | Before | After |
|--------|--------|-------|
| Deployment Target | EC2 Containers | EKS Cluster |
| Build Location | Jenkins on EC2 | Jenkins on EC2 |
| Image Registry | Local Docker | Docker Hub |
| Infrastructure | Single EC2 | Full VPC + EKS |
| High Availability | N/A | 2-5 replicas with HPA |
| Scaling | Manual | Automatic (HPA) |
| Networking | Simple | Advanced (VPC, Subnets, IGW, NAT) |
| Load Balancing | No | AWS NLB/ALB via Service |

## Commands to Run Manually

If you want to skip Jenkins, run manually on EC2:

```bash
# 1. Build images
docker build -t naveen656/student-backend:latest ./backend
docker build -t naveen656/student-frontend:latest ./frontend

# 2. Push to Docker Hub
docker login
docker push naveen656/student-backend:latest
docker push naveen656/student-frontend:latest

# 3. Create EKS cluster
cd terraform
terraform init
terraform plan
terraform apply

# 4. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name student-eks

# 5. Deploy to EKS
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml

# 6. Check status
kubectl get all -n student-app
```

## Troubleshooting

See separate files:
- `DEPLOYMENT-GUIDE.md` - Troubleshooting section
- `README-EKS.md` - Troubleshooting section

## Next Steps

1. Update Jenkinsfile with your values
2. Run `validate.sh` to check setup
3. Run Jenkins job: "Build Now"
4. Monitor progress in Jenkins console
5. Access your application once deployed

---

**Questions?** Check the documentation files or review the configuration step-by-step.
