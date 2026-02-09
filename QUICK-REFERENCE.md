# Quick Reference - Commands & Fixes

## First Time Setup

```bash
# 1. Validate setup
chmod +x validate.sh
./validate.sh

# 2. Login to Docker Hub
docker login

# 3. Initialize Terraform
cd terraform
terraform init
cd ..

# 4. Configure AWS (if not done)
aws configure

# 5. Check AWS access
aws sts get-caller-identity
```

## Running the Pipeline

```bash
# Option 1: Via Jenkins UI
# Go to: Jenkins > student-eks-deployment > Build Now

# Option 2: Via Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080 build student-eks-deployment

# Option 3: Via curl
curl -X POST http://localhost:8080/job/student-eks-deployment/build
```

## Monitoring the Pipeline

```bash
# View pipeline console output
# Jenkins UI: Click build number > Console Output

# Tail logs in real-time (on EC2)
cd terraform
terraform apply -auto-approve 2>&1 | tee deployment.log

# View specific terraform output
terraform output eks_cluster_endpoint
```

## Kubernetes Debugging

### Check Cluster Access
```bash
kubectl cluster-info
kubectl get nodes
```

### View Application
```bash
kubectl get pods -n student-app
kubectl get svc -n student-app
kubectl get all -n student-app
```

### Check Specific Pod
```bash
# View pod status
kubectl describe pod <pod-name> -n student-app

# View pod logs (last 50 lines)
kubectl logs <pod-name> -n student-app --tail=50

# Follow logs in real-time
kubectl logs <pod-name> -n student-app -f
```

### Get Cluster Events
```bash
kubectl get events -n student-app
kubectl get events -n student-app --sort-by='.lastTimestamp'
```

### Check Auto-Scaling
```bash
kubectl get hpa -n student-app
kubectl top pods -n student-app
kubectl top nodes
```

## Common Issues & Fixes

### Issue: Docker push fails
```bash
# Solution 1: Login again
docker logout
docker login
# Enter credentials

# Solution 2: Check image exists
docker ls
docker images | grep student

# Solution 3: Check Docker Hub account permissions
# Ensure account can push to public repo
```

### Issue: Terraform initialization fails
```bash
# Solution: Re-initialize
cd terraform
rm -rf .terraform
terraform init

# With specific version
terraform init -upgrade
```

### Issue: EKS cluster creation hangs
```bash
# Check status
aws eks describe-cluster --name student-eks --region us-east-1 --query 'cluster.status'

# View CloudFormation stack
aws cloudformation describe-stacks --stack-name eks-student-eks

# Cancel and retry
# In Jenkins: Stop build
# Then: terraform destroy (careful!) and retry
```

### Issue: kubectl won't connect
```bash
# Solution 1: Reconfigure
aws eks update-kubeconfig --region us-east-1 --name student-eks

# Solution 2: Check credentials
aws sts get-caller-identity

# Solution 3: Check security groups
aws ec2 describe-security-groups --filter Name=group-name,Values="student-eks*"

# Solution 4: Check cluster is running
aws eks describe-cluster --name student-eks --region us-east-1
```

### Issue: Pods stuck in Pending
```bash
# Check why
kubectl describe pod <pod-name> -n student-app

# Check node resources
kubectl top nodes
kubectl describe nodes

# Check resource requests vs available
kubectl get nodes -o json | jq '.items[].status.allocatable'
```

### Issue: ImagePullBackOff
```bash
# Check image exists
docker image ls | grep student

# Verify in Docker Hub manually
# https://hub.docker.com/repository/docker/naveen656/student-backend

# Check image names match exactly
kubectl describe pod <pod-name> -n student-app | grep Image

# Rebuild and push
docker build -t naveen656/student-backend:latest ./backend
docker push naveen656/student-backend:latest
```

### Issue: Logs show "Connection refused"
```bash
# Check backend is running
kubectl get pods -n student-app -l app=backend

# Check service exists
kubectl get svc backend-service -n student-app

# Test connectivity between pods
kubectl run -it --rm debug --image=busybox --restart=Never -n student-app -- wget -O- http://backend-service:5000
```

### Issue: LoadBalancer pending IP
```bash
# Wait a bit longer
kubectl get svc -n student-app --watch

# Check AWS NLB creation
aws elbv2 describe-load-balancers

# Describe service for errors
kubectl describe svc frontend-service -n student-app
```

## AWS Troubleshooting

### Check IAM Permissions
```bash
# List user policies
aws iam list-attached-user-policies --user-name <your-user>

# Check specific permission
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:user/USERNAME \
  --action-names eks:* \
  --resource-arns "*"
```

### Check VPC & Subnets
```bash
# List VPCs
aws ec2 describe-vpcs --filter Name=tag:Name,Values="student-vpc"

# List subnets
aws ec2 describe-subnets --filter Name=tag:Name,Values="student-*"

# Check security groups
aws ec2 describe-security-groups --filter Name=tag:Name,Values="student-*"
```

### View Terraform State
```bash
cd terraform
terraform state list
terraform state show aws_eks_cluster.student_cluster
terraform show -json > state_backup.json
```

## Performance Optimization

### Monitor resource usage
```bash
kubectl top pods -n student-app --containers
kubectl top nodes --containers
```

### Check HPA metrics
```bash
kubectl get hpa -n student-app
kubectl get hpa backend-hpa -n student-app -o yaml

# Fetch metrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```

### Adjust HPA thresholds
```bash
# Edit HPA
kubectl edit hpa backend-hpa -n student-app

# Or patch it
kubectl patch hpa backend-hpa -n student-app --type merge -p '{"spec":{"maxReplicas": 10}}'
```

## Cleanup Commands

### Stop Everything
```bash
# 1. Delete Kubernetes resources
kubectl delete namespace student-app

# 2. Destroy AWS infrastructure
cd terraform
terraform destroy

# 3. Remove kubeconfig
kubectl config delete-context arn:aws:eks:us-east-1:ACCOUNT:cluster/student-eks
kubectl config delete-cluster arn:aws:eks:us-east-1:ACCOUNT:cluster/student-eks
rm ~/.kube/config

# 4. Remove JWT token cache (optional)
rm -rf ~/.kube/cache

# 5. Remove local Docker images (optional)
docker rmi naveen656/student-backend:latest
docker rmi naveen656/student-frontend:latest
```

### Partial Cleanup
```bash
# Keep EKS, just delete app
kubectl delete namespace student-app

# Restart app
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
```

## Docker Commands on Build Server

```bash
# List images
docker images

# List containers
docker ps -a

# View logs
docker logs -f <container-id>

# Remove old containers
docker container prune

# Remove dangling images
docker image prune

# Clean everything (be careful!)
docker system prune -a
```

## Git Commands

```bash
# Push changes
git add .
git commit -m "Update EKS configuration"
git push origin main

# Pull latest
git pull origin main

# Check status
git status
git diff
```

## Jenkins Troubleshooting

### View Pipeline Logs
```bash
# If SSH access available
tail -f ~/.jenkins/logs/jenkins.logs

# Or view via UI:
# Jenkins menu > System Log
```

### Update Jenkins Credentials
```bash
# Via Jenkins UI:
# Manage Jenkins > Manage Credentials > (domain) > Update password
```

### Run Single Stage
```bash
# In Jenkins UI:
# Use "Replay" button on a past build to test single stages
```

## Useful AWS CLI Commands

```bash
# Get cluster details
aws eks describe-cluster --name student-eks --region us-east-1

# Get node groups
aws eks list-nodegroups --cluster-name student-eks --region us-east-1

# Get node group details
aws eks describe-nodegroup --cluster-name student-eks --nodegroup-name student-node-group --region us-east-1

# Check CloudFormation stacks
aws cloudformation list-stacks --region us-east-1 --query 'StackSummaries[] | [?contains(StackName, `student`)]'

# Get cost estimate (basic)
aws ce get-cost-and-usage \
  --time-period Start=2024-02-01,End=2024-02-09 \
  --granularity DAILY \
  --metrics BlendedCost \
  --region us-east-1
```

## Useful kubectl Aliases

```bash
# Add to ~/.bashrc or ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kdesc='kubectl describe'
alias klogs='kubectl logs'
alias kctx='kubectl config current-context'

# Then reload
source ~/.bashrc
```

---

**Remember**: Most issues are temporary and retry often works. Check logs first!
