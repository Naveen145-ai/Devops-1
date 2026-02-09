# Quick Deployment Guide

This guide walks you through deploying the student application to AWS EKS using Jenkins.

## Prerequisites Checklist

- [ ] Jenkins installed on EC2 with pipeline support
- [ ] Docker installed and running on EC2
- [ ] Terraform installed on EC2
- [ ] kubectl installed on EC2
- [ ] AWS CLI installed and configured with credentials
- [ ] Docker Hub account and credentials
- [ ] AWS Account with IAM permissions for EKS, EC2, VPC, and IAM
- [ ] Git access to this repository

## Step-by-Step Deployment

### 1. Prepare Jenkins

1. Log in to Jenkins dashboard (default: http://localhost:8080)
2. Navigate to "Manage Jenkins" → "Manage Credentials"
3. Add new credentials:
   - **aws-credentials** (AWS Credentials type):
     - Access Key ID: `your-access-key`
     - Secret Access Key: `your-secret-key`
   
   - **dockerhub-creds** (Username with password type):
     - Username: `your-docker-username`
     - Password: `your-docker-password`

### 2. Create Jenkins Pipeline Job

1. Click "New Item"
2. Enter job name: `student-eks-deployment`
3. Select "Pipeline"
4. In "Pipeline" section:
   - Definition: "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: `https://github.com/your-username/Devops-1.git`
   - Branch: `*/main` or `*/master`
5. Click "Save"

### 3. Update Configuration Files

Edit these files with your values:

**Jenkinsfile** (lines 3-10):
```groovy
environment {
  DOCKER_USER = "your-docker-username"  # Change this
  AWS_REGION = "us-east-1"
  EKS_CLUSTER_NAME = "student-eks"
  AWS_ACCOUNT_ID = "123456789012"       # Change this
}
```

**terraform/variables.tf** (optional):
- `aws_region` - AWS region (default: us-east-1)
- `desired_size` - Number of worker nodes (default: 2)
- `instance_types` - Node instance type (default: t3.medium)

### 4. Run the Pipeline

1. Go to your Jenkins job: `student-eks-deployment`
2. Click "Build Now"
3. Monitor the build in "Build History"

### 5. Pipeline Stages Explained

| Stage | Description | Duration |
|-------|-------------|----------|
| Checkout | Clones the repository | < 1 min |
| Docker Login | Authenticates with Docker Hub | < 1 min |
| Build Backend | Builds backend Docker image | 2-5 min |
| Build Frontend | Builds frontend Docker image | 2-5 min |
| Push Images | Pushes images to Docker Hub | 1-3 min |
| Create EKS Cluster | Creates AWS EKS cluster (first time only) | 10-15 min |
| Configure kubectl | Sets up kubectl access | < 1 min |
| Deploy to EKS | Deploys containers to the cluster | 2-5 min |

**Total time: 20-40 minutes (first run), 10-20 minutes (subsequent runs)**

### 6. Verify Deployment

After pipeline completes successfully:

```bash
# Get cluster info
kubectl cluster-info

# Check running pods
kubectl get pods -n student-app

# Get frontend external IP
kubectl get svc -n student-app

# View application logs
kubectl logs -n student-app -l app=frontend

# Monitor HPA (auto-scaling)
kubectl get hpa -n student-app
```

### 7. Access Your Application

1. Get the LoadBalancer external IP:
   ```bash
   kubectl get svc frontend-service -n student-app
   ```

2. Open browser and go to: `http://<EXTERNAL-IP>`

3. Application should be running!

## Common Commands

### Kubernetes Debugging

```bash
# View all resources in the app namespace
kubectl get all -n student-app

# View pod details
kubectl describe pod <pod-name> -n student-app

# View pod logs
kubectl logs <pod-name> -n student-app

# Get into a pod (if tools available)
kubectl exec -it <pod-name> -n student-app -- /bin/bash

# Scale deployment
kubectl scale deployment student-backend --replicas=3 -n student-app

# View service endpoints
kubectl endpoints student-backend-service -n student-app
```

### Terraform Management

```bash
# From jenkins ec2 server
cd terraform

# Check what will change
terraform plan

# View current state
terraform show

# Destroy all resources (careful!)
terraform destroy
```

### Docker on Jenkins Server

```bash
# View local images
docker images

# View running containers
docker ps

# View logs
docker logs <container-id>

# Remove images (after pushing to Docker Hub)
docker image rm <image-id>
```

## Troubleshooting

### Pods stuck in Pending state
```bash
kubectl describe pod <pod-name> -n student-app
# Check: resource allocation, node availability, image pull errors
```

### ImagePullBackOff error
- Verify Docker Hub images exist
- Check image names in deployment files
- Ensure image is public or credentials are configured

### EKS cluster creation fails
- Check AWS credentials: `aws sts get-caller-identity`
- Check IAM permissions for EKS
- Check AWS VPC and subnet quotas
- Review Terraform logs in Jenkins console

### kubectl can't connect to cluster
```bash
# Reconfigure kubeconfig
aws eks update-kubeconfig --region us-east-1 --name student-eks

# Verify connection
kubectl cluster-info
```

### Deployment won't start
```bash
# Check for errors
kubectl describe deployment student-backend -n student-app

# Check events
kubectl get events -n student-app

# View logs
kubectl logs -n student-app -l app=backend
```

## Monitoring

### Real-time pod monitoring
```bash
kubectl get pods -n student-app --watch
```

### Resource usage
```bash
# Pod resource usage
kubectl top pods -n student-app

# Node resource usage
kubectl top nodes
```

### HPA status
```bash
kubectl get hpa -n student-app
kubectl describe hpa backend-hpa -n student-app
```

## Cleanup

To stop AWS charges:

```bash
# From ec2-server, in the repo directory
cd terraform

# Destroy EKS cluster and all infrastructure
terraform destroy

# Confirm by typing 'yes'
```

## Important Notes

1. **First deployment takes 15+ minutes** - EKS cluster creation is slow
2. **AWS charges apply** - ~$75/month for this setup
3. **Terraform state is important** - Keep `terraform.tfstate` safe
4. **Images need to exist** - Docker Hub images must be built and pushed
5. **Jenkins needs credentials** - Must add AWS and Docker credentials first

## Support

Check these logs if something goes wrong:

1. **Jenkins**: Click on the build number → "Console Output"
2. **Terraform**: Logs appear in Jenkins console
3. **Kubernetes**: `kubectl get events -n student-app`
4. **Docker**: `docker logs <container-name>`
5. **AWS**: CloudFormation stack events in AWS console

## Next Steps After Deployment

1. Set up monitoring (CloudWatch, Prometheus)
2. Configure ingress for custom domains
3. Set up TLS/SSL certificates
4. Implement auto-scaling policies
5. Set up backup and disaster recovery
