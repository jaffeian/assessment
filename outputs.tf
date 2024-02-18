output "vpc_cidr" {
    value = aws_vpc.main.cidr_block
}

output "public_subnet_1a" {
    value = aws_subnet.public_subnet_1a.cidr_block
}

output "public_subnet_1b" {
    value = aws_subnet.public_subnet_1b.cidr_block
}

output "private_subnet_1a" {
    value = aws_subnet.private_subnet_1a.cidr_block
}

output "private_subnet_1b" {
    value = aws_subnet.private_subnet_1b.cidr_block
}

output "load_balancer_dns_name" {
    value = aws_lb.front.dns_name
}

output "web_instance_id" {
    value = aws_instance.web_instance.id
}

output "eks_cluster_name" {
    value = aws_eks_cluster.ekscluster.name
}

