source /var/tmp/envs-ocp4

echo "Create the VPC"
aws ec2 create-vpc --cidr-block ${VpcCidr}
VpcId=$(aws ec2 describe-vpcs | jq -r '.Vpcs[] | select(.CidrBlock=="10.0.0.0/16")? | .VpcId')
echo "export VpcId=$VpcId" >> ${LOGFILE}

aws ec2 modify-vpc-attribute --vpc-id ${VpcId} --enable-dns-hostnames "{\"Value\":true}"
aws ec2 describe-vpc-attribute --attribute enableDnsHostnames --vpc-id  ${VpcId}
aws ec2 describe-vpc-attribute --attribute enableDnsSupport --vpc-id  ${VpcId}
aws ec2 create-tags --tags Key=Name,Value=${customer}-vpc --resources ${VpcId}
DhcpOptionsId=$(aws ec2 describe-vpcs --vpc-ids ${VpcId} | jq -r .Vpcs[0].DhcpOptionsId)
aws ec2 describe-dhcp-options --dhcp-options-ids ${DhcpOptionsId}
echo "export DhcpOptionsId=$DhcpOptionsId" >> ${LOGFILE}

echo "Create subnets"
echo "Create the public facing network"
# TODO fix the args
aws ec2 create-subnet --vpc-id ${VpcId} --cidr-block ${SubnetPublicCidr} --availability-zone ${AvailabilityZone0} --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=rcarrata-public-subnet-1a}]'
PublicSubnetId=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${customer}-public-subnet-1a" | jq -r '.Subnets[].SubnetId')
echo "export PublicSubnetId=$PublicSubnetId" >> ${LOGFILE}

echo "Create the 3 private Networks"
# TODO: Fix the --tags for create directly"
aws ec2 create-subnet --availability-zone ${AvailabilityZone0} --cidr-block ${Subnet0Cidr} --vpc-id ${VpcId} --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=rcarrata-private-subnet-1a}]'
PrivateSubnet0Id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${customer}-private-subnet-1a" | jq -r '.Subnets[].SubnetId')
echo "export PrivateSubnet0Id=$PrivateSubnet0Id" >> ${LOGFILE}

aws ec2 create-subnet --availability-zone ${AvailabilityZone1} --cidr-block ${Subnet1Cidr} --vpc-id ${VpcId} --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=rcarrata-private-subnet-1b}]'
PrivateSubnet1Id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${customer}-private-subnet-1b" | jq -r '.Subnets[].SubnetId')
echo "export PrivateSubnet1Id=$PrivateSubnet1Id" >> ${LOGFILE}

aws ec2 create-subnet --availability-zone ${AvailabilityZone2} --cidr-block ${Subnet2Cidr} --vpc-id ${VpcId} --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=rcarrata-private-subnet-1c}]'
PrivateSubnet2Id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${customer}-private-subnet-1c" | jq -r '.Subnets[].SubnetId')
echo "export PrivateSubnet2Id=$PrivateSubnet2Id" >> ${LOGFILE}

echo "Create internet gateway for bastion/proxy host in public network and attach it to the VPC"

aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=rcarrata-igw}]'

InternetGatewayId=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=${customer}-igw" | jq -r '.InternetGateways[].InternetGatewayId')
echo "export InternetGatewayId=$InternetGatewayId" >> ${LOGFILE}

aws ec2 attach-internet-gateway --internet-gateway-id ${InternetGatewayId} --vpc-id ${VpcId}

echo "Create Routing Table"

echo "Public Route Table"
aws ec2 create-route-table --vpc-id ${VpcId} --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=rcarrata-public-rtb}]'
PublicRouteTableId=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=${customer}-public-rtb" | jq -r .RouteTables[].RouteTableId)
echo "export PublicRouteTableId=$PublicRouteTableId" >> ${LOGFILE}

echo "Private Route Table"
aws ec2 create-route-table --vpc-id ${VpcId} --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=rcarrata-private-rtb}]'
PrivateRouteTableId=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=${customer}-private-rtb" | jq -r .RouteTables[].RouteTableId)
echo "export PrivateRouteTableId=$PrivateRouteTableId" >> ${LOGFILE}

echo "Link to Internet Gateway"
aws ec2 create-route --destination-cidr-block 0.0.0.0/0 --gateway-id ${InternetGatewayId} --route-table-id ${PublicRouteTableId}

echo "Associate routing tables to subnets"
echo "Associate public subnets"
aws ec2 associate-route-table  --subnet-id ${PublicSubnetId} --route-table-id ${PublicRouteTableId}

echo "Associate private subnets"
aws ec2 associate-route-table  --subnet-id ${PrivateSubnet0Id} --route-table-id ${PrivateRouteTableId}
aws ec2 associate-route-table  --subnet-id ${PrivateSubnet1Id} --route-table-id ${PrivateRouteTableId}
aws ec2 associate-route-table  --subnet-id ${PrivateSubnet2Id} --route-table-id ${PrivateRouteTableId}

echo "Create Security Groups"
echo "Public"
aws ec2 create-security-group --group-name "${customer}-public-sg" --description "${customer}-public-sg" --vpc-id ${VpcId} --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=rcarrata-public-sg}]'
PublicSecurityGroupId=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${customer}-public-sg" | jq -r .SecurityGroups[].GroupId)
echo "export PublicSecurityGroupId=$PublicSecurityGroupId" >> ${LOGFILE}

aws ec2 authorize-security-group-ingress --group-id ${PublicSecurityGroupId} --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${PublicSecurityGroupId} --protocol all --cidr ${VpcCidr}
aws ec2 describe-security-groups --group-id ${PublicSecurityGroupId} | jq -r

echo "Private"
aws ec2 create-security-group --group-name "${customer}-private-sg" --description "${customer}-private-sg" --vpc-id ${VpcId} --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=rcarrata-private-sg}]'

PrivateSecurityGroup=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${customer}-private-sg" | jq -r .SecurityGroups[].GroupId)
echo "export PrivateSecurityGroup=$PrivateSecurityGroup" >> ${LOGFILE}

aws ec2 authorize-security-group-ingress --group-id ${PrivateSecurityGroup} --protocol all --cidr ${VpcCidr}
aws ec2 authorize-security-group-egress  --group-id  ${PrivateSecurityGroup} --protocol all  --cidr ${VpcCidr}
aws ec2 revoke-security-group-egress --group-id ${PrivateSecurityGroup} --protocol all --cidr 0.0.0.0/0
aws ec2 describe-security-groups --group-id ${PrivateSecurityGroup} | jq -r

echo "Create VPC Endpoints"
echo "Create the VPC endpoint for the s3 Service"
aws ec2 create-vpc-endpoint --vpc-endpoint-type Gateway --vpc-id ${VpcId} --service-name ${s3Endpoint} --route --route-table-ids ${PrivateRouteTableId} --no-private-dns-enabled --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=rcarrata-EP-s3}]'

echo "Create the VPC endpoint for the ELB Service"
aws ec2 create-vpc-endpoint --vpc-endpoint-type Interface --vpc-id ${VpcId} --service-name ${elbEndpoint} --subnet-ids ${PrivateSubnet0Id} ${PrivateSubnet1Id} ${PrivateSubnet2Id} --private-dns-enabled --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=rcarrata-EP-elb}]'

elbEPid=$(aws ec2 describe-vpc-endpoints --filter "Name=vpc-id,Values=$VpcId" --filters "Name=tag:Name,Values=rcarrata-EP-elb" | jq -r .VpcEndpoints[].VpcEndpointId)
elbEPSgDefault=$(aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $elbEPid | jq -r .VpcEndpoints[].Groups[].GroupId)
aws ec2 modify-vpc-endpoint --vpc-endpoint-id ${elbEPid} --add-security-group-ids ${elbEPSgDefault} --add-security-group-ids ${PublicSecurityGroupId}
aws ec2 modify-vpc-endpoint --vpc-endpoint-id ${elbEPid} --remove-security-group-ids ${elbEPSgDefault}

echo "Create the VPC endpoint for the EC2 Service"
aws ec2 create-vpc-endpoint --vpc-endpoint-type Interface --vpc-id ${VpcId} --service-name ${ec2Endpoint} --security-group-ids ${PublicSecurityGroupId} --subnet-ids ${PrivateSubnet0Id} ${PrivateSubnet1Id} ${PrivateSubnet2Id} --private-dns-enabled --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=rcarrata-EP-ec2}]'