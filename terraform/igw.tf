resource "aws_internet_gateway" "igw-vaction" {
  vpc_id = aws_vpc.vpc-vaction.id

  tags = {
    Name = "igw-vpc-vaction"
  }
}