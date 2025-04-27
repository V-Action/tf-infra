resource "aws_vpc" "vpc-vaction" {
  cidr_block = "10.0.0.0/23"

  tags = {
    Name = "vpc-vaction"
  }
}