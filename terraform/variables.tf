variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_az1" {
  description = "CIDR block for public subnet in AZ1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_az2" {
  description = "CIDR block for public subnet in AZ2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_az1" {
  description = "CIDR block for private subnet in AZ1"
  type        = string
  default     = "10.0.11.0/24"
}

variable "private_subnet_az2" {
  description = "CIDR block for private subnet in AZ2"
  type        = string
  default     = "10.0.12.0/24"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "student-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}
