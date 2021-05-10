data "aws_vpc" "cluster_vpc" {
  id = aws_vpc.new_vpc.id
}

data "aws_subnet" "public" {
  count = 1

  id = aws_subnet.public_subnet[count.index].id
}

data "aws_subnet" "private" {
  count = 3

  id = aws_subnet.private_subnet[count.index].id
}
