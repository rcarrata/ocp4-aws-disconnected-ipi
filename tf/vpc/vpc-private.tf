# Private Subnets 
resource "aws_subnet" "private_subnet" {
  count = 3

  vpc_id = data.aws_vpc.cluster_vpc.id

  cidr_block = cidrsubnet(local.new_private_cidr_range, 2, count.index)

  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      "Name" = "${var.clustername}-private-${var.availability_zones[count.index]}"
    },
    var.tags,
  )
}

# 1 x Private Route Table
resource "aws_route_table" "private_routes" {

  vpc_id = data.aws_vpc.cluster_vpc.id

  tags = merge(
    {
      "Name" = "${var.clustername}-private-rt"
    },
    var.tags,
  )
}

resource "aws_route_table_association" "private_routing" {
  count = 3

  route_table_id = aws_route_table.private_routes.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}

# No Route Table Entries because with the default of VPC Destination route it's enough
