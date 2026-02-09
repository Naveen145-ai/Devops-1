#!/bin/bash

# Student DevOps Project - Setup Script
# This script helps configure the Jenkins pipeline for EKS deployment

set -e

echo "=========================================="
echo "Student DevOps Project - Setup Script"
echo "=========================================="
echo ""

# 1. Check prerequisites
echo "1. Checking Prerequisites..."
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed."; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "AWS CLI is required but not installed."; exit 1; }
echo "✓ All prerequisites met"
echo ""

# 2. Configure AWS credentials
echo "2. Configuring AWS Credentials..."
if [ ! -f ~/.aws/credentials ]; then
    echo "AWS credentials not found. Please configure AWS CLI:"
    echo "  aws configure"
    exit 1
else
    echo "✓ AWS credentials found"
fi
echo ""

# 3. Configure Docker Hub credentials
echo "3. Docker Hub Configuration"
read -p "Enter your Docker Hub username: " DOCKER_USER
read -s -p "Enter your Docker Hub password: " DOCKER_PASSWORD
echo ""

echo "✓ Docker Hub credentials saved"
echo ""

# 4. Get AWS Account ID
echo "4. Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -z "$AWS_ACCOUNT_ID" ]; then
    read -p "Enter your AWS Account ID: " AWS_ACCOUNT_ID
fi
echo "✓ AWS Account ID: $AWS_ACCOUNT_ID"
echo ""

# 5. Initialize Terraform
echo "5. Initializing Terraform..."
cd terraform
terraform init
cd ..
echo "✓ Terraform initialized"
echo ""

# 6. Validate Kubernetes manifests
echo "6. Validating Kubernetes manifests..."
kubectl apply -f k8s/backend-deployment.yaml --dry-run=client || { echo "Backend manifest validation failed"; exit 1; }
kubectl apply -f k8s/frontend-deployment.yaml --dry-run=client || { echo "Frontend manifest validation failed"; exit 1; }
echo "✓ Kubernetes manifests validated"
echo ""

# 7. Summary
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Add these credentials to Jenkins:"
echo "   - aws-credentials: AWS Access Key ID & Secret"
echo "   - dockerhub-creds: Docker Hub username & password"
echo ""
echo "2. Update Jenkinsfile with:"
echo "   - DOCKER_USER = \"$DOCKER_USER\""
echo "   - AWS_ACCOUNT_ID = \"$AWS_ACCOUNT_ID\""
echo ""
echo "3. Run your Jenkins pipeline to build, push, and deploy!"
echo ""
echo "To verify your configuration:"
echo "  - Docker: docker ps"
echo "  - AWS: aws sts get-caller-identity"
echo "  - Terraform: cd terraform && terraform plan"
echo "  - Kubectl: kubectl cluster-info"
