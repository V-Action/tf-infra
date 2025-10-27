resource "aws_vpc" "vpc-vaction" {
  cidr_block = var.vpc_cidr # "10.0.0.0/21"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-vaction"
  }
}