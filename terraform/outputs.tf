output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.student_cluster.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = aws_eks_cluster.student_cluster.endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.student_cluster.version
}

output "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster control plane"
  value       = aws_security_group.eks_control_plane.id
}

output "eks_node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.student_nodes.id
}

output "eks_node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.student_nodes.status
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.student_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
}

output "nat_gateway_ip" {
  description = "Elastic IP of NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "configure_kubectl_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.student_cluster.name}"
}
