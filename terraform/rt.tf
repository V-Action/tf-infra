resource "aws_route_table" "rt-public-vaction" {
  vpc_id = aws_vpc.vpc-vaction.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-vaction.id
  }

  tags = {
    Name = "public-route-table"
  }
}



resource "aws_route_table" "rt-private-vaction" {
  vpc_id = aws_vpc.vpc-vaction.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-vaction.id
  }

  tags = {
    Name = "private-route-table"
  }

}


resource "aws_route_table_association" "assoc_public_a" {
subnet_id = aws_subnet.public.id
route_table_id = aws_route_table.rt-public-vaction.id
}

resource "aws_route_table_association" "assoc_public_b" {
subnet_id = aws_subnet.public_b.id
route_table_id = aws_route_table.rt-public-vaction.id
}

resource "aws_route_table_association" "assoc_private" {
subnet_id = aws_subnet.private.id
route_table_id = aws_route_table.rt-private-vaction.id
}