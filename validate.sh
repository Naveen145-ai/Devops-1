#!/bin/bash

# Student DevOps Project - Validation Script
# Checks if all dependencies and configurations are properly set up

set +e

PASSED=0
FAILED=0
WARNINGS=0

# color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Validation Checklist"
echo "==========================================${NC}\n"

# Check Docker
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    if docker ps &> /dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC} (Docker not running)"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗ FAIL${NC} (Docker not installed)"
    ((FAILED++))
fi

# Check Docker Hub login
echo -n "Checking Docker Hub credentials... "
if docker info | grep -q "Username:"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ WARNING${NC} (Not logged in, will fail at push stage)"
    ((WARNINGS++))
fi

# Check Terraform
echo -n "Checking Terraform... "
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform -v | head -n1)
    echo -e "${GREEN}✓ PASS${NC} ($TERRAFORM_VERSION)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (Terraform not installed)"
    ((FAILED++))
fi

# Check Terraform initialization
echo -n "Checking Terraform initialization... "
if [ -d "terraform/.terraform" ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠ WARNING${NC} (Need to run: cd terraform && terraform init)"
    ((WARNINGS++))
fi

# Check kubectl
echo -n "Checking kubectl... "
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | awk '{print $NF}')
    echo -e "${GREEN}✓ PASS${NC} ($KUBECTL_VERSION)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (kubectl not installed)"
    ((FAILED++))
fi

# Check AWS CLI
echo -n "Checking AWS CLI... "
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version | awk '{print $1}')
    echo -e "${GREEN}✓ PASS${NC} ($AWS_VERSION)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (AWS CLI not installed)"
    ((FAILED++))
fi

# Check AWS credentials
echo -n "Checking AWS credentials... "
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
    echo -e "${GREEN}✓ PASS${NC}"
    echo "  └─ Account: $AWS_ACCOUNT"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (AWS credentials not configured)"
    echo "  └─ Run: aws configure"
    ((FAILED++))
fi

# Check Git
echo -n "Checking Git... "
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo -e "${GREEN}✓ PASS${NC} ($GIT_VERSION)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} (Git not installed)"
    ((FAILED++))
fi

# Check required files
echo -e "\n${BLUE}Checking Required Files:${NC}"

FILES=(
    "Jenkinsfile"
    "backend/Dockerfile"
    "frontend/Dockerfile"
    "k8s/backend-deployment.yaml"
    "k8s/frontend-deployment.yaml"
    "terraform/main.tf"
    "terraform/variables.tf"
)

for file in "${FILES[@]}"; do
    echo -n "  $file... "
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC}"
        ((FAILED++))
    fi
done

# Check configuration
echo -e "\n${BLUE}Checking Configuration:${NC}"

# Check Jenkinsfile for DOCKER_USER placeholder
echo -n "  Jenkinsfile - DOCKER_USER... "
if grep -q 'DOCKER_USER = "naveen656"' Jenkinsfile; then
    echo -e "${YELLOW}⚠${NC} (Update to your username)"
    ((WARNINGS++))
elif grep -q 'DOCKER_USER = "' Jenkinsfile; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} (Missing DOCKER_USER)"
    ((FAILED++))
fi

# Check Jenkinsfile for AWS_ACCOUNT_ID placeholder
echo -n "  Jenkinsfile - AWS_ACCOUNT_ID... "
if grep -q 'AWS_ACCOUNT_ID = "YOUR_AWS_ACCOUNT_ID"' Jenkinsfile; then
    echo -e "${RED}✗${NC} (Update to your AWS Account ID)"
    ((FAILED++))
elif grep -q 'AWS_ACCOUNT_ID = "' Jenkinsfile; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} (Missing AWS_ACCOUNT_ID)"
    ((FAILED++))
fi

# Summary
echo -e "\n${BLUE}=========================================="
echo "Summary${NC}"
echo -e "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
fi
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
fi

echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed! Ready to deploy.${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠ Please address warnings before deploying.${NC}"
        echo ""
        echo "Run these commands to prepare:"
        echo "  docker login"
        echo "  cd terraform && terraform init && cd .."
        exit 0
    fi
else
    echo -e "${RED}✗ Please fix the failed items before deploying.${NC}"
    exit 1
fi
