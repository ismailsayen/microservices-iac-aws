output "vpc_id" {
  value       = aws_vpc.my_vpc.id
}

output "public_subnets_ids" {
  value       = [for subnet in aws_subnet.subnet_public : subnet.id]
}

output "private_subnets_ids" {
  value       = [for subnet in aws_subnet.subnet_private : subnet.id]
}