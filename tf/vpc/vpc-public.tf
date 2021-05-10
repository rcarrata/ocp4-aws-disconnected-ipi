# Create Public Subnet and attach to VPC 
resource "aws_subnet" "public_subnet" {
  count = 1

  vpc_id            = data.aws_vpc.cluster_vpc.id
  cidr_block        = cidrsubnet(local.new_public_cidr_range, 7, 3)
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      "Name" = "${var.clustername}-public-${var.availability_zones[count.index]}"
    },
    var.tags,
  )
}

# Create a Internet Gateway and Attach to the VPC
resource "aws_internet_gateway" "igw" {

  vpc_id = data.aws_vpc.cluster_vpc.id

  tags = merge(
    {
      "Name" = "${var.clustername}-igw"
    },
    var.tags,
  )
}

# Create a Public Route Table and attach to VPC
resource "aws_route_table" "public_subnet" {

  vpc_id = data.aws_vpc.cluster_vpc.id

  tags = merge(
    {
      "Name" = "${var.clustername}-rt-public"
    },
    var.tags,
  )
}

# Only association to the Public Route Table (not allow Private Subnets to exit internet)
resource "aws_route_table_association" "public_route_table_association" {
  count          = 1
  subnet_id      = data.aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_subnet.id
}

# Route to Internet into the Public Route Table
resource "aws_route" "igw_route" {

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public_subnet.id
  gateway_id             = aws_internet_gateway.igw.id

  timeouts {
    create = "20m"
  }
}

# No Nat Gateway is needed because it's private / disconnected environment.
