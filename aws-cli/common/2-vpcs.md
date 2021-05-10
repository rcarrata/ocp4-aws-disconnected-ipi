## VPCs

### Automated

```
bash -x 03-vpcs.sh
```

### Manual

Now we can start creating aws objects from the local machine

2. Create the VPC

```
source envs-ocp4
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
```

3. Create subnets

* Create the public facing network

```
aws ec2 create-subnet --vpc-id ${VpcId} --cidr-block ${SubnetPublicCidr} --availability-zone ${AvailabilityZone0} --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=rcarrata-public-subnet-1a}]'
PublicSubnetId=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${customer}-public-subnet-1a" | jq -r '.Subnets[].SubnetId')
echo "export PublicSubnetId=$PublicSubnetId" >> ${LOGFILE}
```

* Create 3 private networks

```
# TODO: Fix the --tags for create directly
aws ec2 create-subnet --availability-zone ${AvailabilityZone0} --cidr-block ${Subnet0Cidr} --vpc-id ${VpcId} --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=rcarrata-private-subnet-1a}]'
PrivateSubnet0Id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${customer}-private-subnet-1a" | jq -r '.Subnets[].SubnetId')
echo "export PrivateSubnet0Id=$PrivateSubnet0Id" >> ${LOGFILE}
```

```
aws ec2 create-subnet --availability-zone ${AvailabilityZone1} --cidr-block ${Subnet1Cidr} --vpc-id ${VpcId} --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=rcarrata-private-subnet-1b}]'
PrivateSubnet1Id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${customer}-private-subnet-1b" | jq -r '.Subnets[].SubnetId')
echo "export PrivateSubnet1Id=$PrivateSubnet1Id" >> ${LOGFILE}
```

```
aws ec2 create-subnet --availability-zone ${AvailabilityZone2} --cidr-block ${Subnet2Cidr} --vpc-id ${VpcId} --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=rcarrata-private-subnet-1c}]'
PrivateSubnet2Id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=${customer}-private-subnet-1c" | jq -r '.Subnets[].SubnetId')
echo "export PrivateSubnet2Id=$PrivateSubnet2Id" >> ${LOGFILE}
```

4. Create internet gateway for bastion/proxy host in public network and attach it to the VPC

```
aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=rcarrata-igw}]'

InternetGatewayId=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=${customer}-igw" | jq -r '.InternetGateways[].InternetGatewayId')
echo "export InternetGatewayId=$InternetGatewayId" >> ${LOGFILE}

aws ec2 attach-internet-gateway --internet-gateway-id ${InternetGatewayId} --vpc-id ${VpcId}
```

NOTE: the NAT Gateway is not needed here because we WON'T be connecting the AWS Private Zone to Internet, ONLY to the proxy and through them to Internet (simulating the Private Environment of the Customer) or to be connecting the bastion to internet to mirror the content in the disconnected environments.

5. Create routing tables

* Public Route Table

```
aws ec2 create-route-table --vpc-id ${VpcId} --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=rcarrata-public-rtb}]'

PublicRouteTableId=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=${customer}-public-rtb" | jq -r .RouteTables[].RouteTableId)
echo "export PublicRouteTableId=$PublicRouteTableId" >> ${LOGFILE}
```

* Private Route Table

```
aws ec2 create-route-table --vpc-id ${VpcId} --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=rcarrata-private-rtb}]'
PrivateRouteTableId=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=${customer}-private-rtb" | jq -r .RouteTables[].RouteTableId)
echo "export PrivateRouteTableId=$PrivateRouteTableId" >> ${LOGFILE}
```

6. Link to Internet Gateway

```
aws ec2 create-route --destination-cidr-block 0.0.0.0/0 --gateway-id ${InternetGatewayId} --route-table-id ${PublicRouteTableId}
```

7. describe/check created route tables

```
aws ec2 describe-route-tables --route-table-id ${PublicRouteTableId}
aws ec2 describe-route-tables --route-table-id ${PrivateRouteTableId}
```

```
aws ec2 describe-subnets --filters --filters "Name=vpc-id,Values=${VpcId}" --output text
aws ec2 describe-subnets --filters --filters "Name=vpc-id,Values=${VpcId}" --query 'Subnets[*].[AvailabilityZone,CidrBlock,SubnetId]' --output table
```

8. Associate routing tables to subnets

* Associate public subnets

```
aws ec2 associate-route-table  --subnet-id ${PublicSubnetId} --route-table-id ${PublicRouteTableId}
```

* Associate private subnets

```
aws ec2 associate-route-table  --subnet-id ${PrivateSubnet0Id} --route-table-id ${PrivateRouteTableId}
aws ec2 associate-route-table  --subnet-id ${PrivateSubnet1Id} --route-table-id ${PrivateRouteTableId}
aws ec2 associate-route-table  --subnet-id ${PrivateSubnet2Id} --route-table-id ${PrivateRouteTableId}
```

You can optionally modify the public IP addressing behavior of your subnet so that an instance launched into the subnet automatically receives a public IP address. Otherwise, you should associate an Elastic IP address with your instance after launch so that it's reachable from the Internet. 


9. Check Network ACLs

```
aws ec2 describe-network-acls --filter "Name=vpc-id,Values=${VpcId}"
```

10. Create Security Groups

creating 2 security groups 

* **public** one for the bastion and which we need to assign to an endpoint as well to run aws cli and ocp installer from it (otherwise it fails)

```
aws ec2 create-security-group --group-name "${customer}-public-sg" --description "${customer}-public-sg" --vpc-id ${VpcId} --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=rcarrata-public-sg}]'
PublicSecurityGroupId=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${customer}-public-sg" | jq -r .SecurityGroups[].GroupId)
echo "export PublicSecurityGroupId=$PublicSecurityGroupId" >> ${LOGFILE}
```

TODO: make this security groups more restrictive

```
aws ec2 authorize-security-group-ingress --group-id ${PublicSecurityGroupId} --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id ${PublicSecurityGroupId} --protocol all --cidr ${VpcCidr}
aws ec2 describe-security-groups --group-id ${PublicSecurityGroupId} | jq -r
```

* **private one** which is there for the private nets too test proxy and is not needed for the actual setup

```
aws ec2 create-security-group --group-name "${customer}-private-sg" --description "${customer}-private-sg" --vpc-id ${VpcId} --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=rcarrata-private-sg}]'

PrivateSecurityGroup=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${customer}-private-sg" | jq -r .SecurityGroups[].GroupId)
echo "export PrivateSecurityGroup=$PrivateSecurityGroup" >> ${LOGFILE}
```

```
aws ec2 authorize-security-group-ingress --group-id ${PrivateSecurityGroup} --protocol all --cidr ${VpcCidr}
aws ec2 authorize-security-group-egress  --group-id  ${PrivateSecurityGroup} --protocol all  --cidr ${VpcCidr}
aws ec2 revoke-security-group-egress --group-id ${PrivateSecurityGroup} --protocol all --cidr 0.0.0.0/0
aws ec2 describe-security-groups --group-id ${PrivateSecurityGroup} | jq -r
```

The ingress/egress are limited only to the VpcCidr, to avoid to leave internet through the nat GW or to any Route Table, assuring that the VPC is privated and only exits using the Proxy or no exit at all to Internet. 

13. Create VPC Endpoints

ec2 and elasticloadbalancing are needed as otherwise worker nodes will not be created

both need to be assigned to 3 private subnets
if not specifically changed/configured default sg will be automatically assigned
especially for ec2 endpoint it is important to specify the public security group as otherwise aws cli and openshift-installer will not be able to communicate with AWS api and nothing will happen at all
elasticloadbalancing ep has no such requirement according to testing, however as I find the default sg too open I also assigne the public sg I created


```
# aws ec2 describe-vpc-endpoint-services | grep -A3 s3  | grep ServiceName
            "ServiceName": "com.amazonaws.eu-west-1.s3",
            "ServiceName": "com.amazonaws.eu-west-1.s3",
```


* Create the VPC endpoint for the s3 Service

```
aws ec2 create-vpc-endpoint --vpc-endpoint-type Gateway --vpc-id ${VpcId} --service-name ${s3Endpoint} --route --route-table-ids ${PrivateRouteTableId} --no-private-dns-enabled --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=rcarrata-EP-s3}]'
```

* Create the VPC endpoint for the ELB Service

```
aws ec2 create-vpc-endpoint --vpc-endpoint-type Interface --vpc-id ${VpcId} --service-name ${elbEndpoint} --subnet-ids ${PrivateSubnet0Id} ${PrivateSubnet1Id} ${PrivateSubnet2Id} --private-dns-enabled --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=rcarrata-EP-elb}]'
```

We check it and replace the default security group by the public one created manually 
As at least one security group must be present we add first add the public one and then remove the default one

```
elbEPid=$(aws ec2 describe-vpc-endpoints --filter "Name=vpc-id,Values=$VpcId" --filters "Name=tag:Name,Values=rcarrata-EP-elb" | jq -r .VpcEndpoints[].VpcEndpointId)
elbEPSgDefault=$(aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $elbEPid | jq -r .VpcEndpoints[].Groups[].GroupId)
aws ec2 modify-vpc-endpoint --vpc-endpoint-id ${elbEPid} --add-security-group-ids ${elbEPSgDefault} --add-security-group-ids ${PublicSecurityGroupId}
aws ec2 modify-vpc-endpoint --vpc-endpoint-id ${elbEPid} --remove-security-group-ids ${elbEPSgDefault}
```

https://docs.aws.amazon.com/vpc/latest/privatelink/vpce-interface.html

* Create the VPC endpoint for the EC2 Service

```
aws ec2 create-vpc-endpoint --vpc-endpoint-type Interface --vpc-id ${VpcId} --service-name ${ec2Endpoint} --security-group-ids ${PublicSecurityGroupId} --subnet-ids ${PrivateSubnet0Id} ${PrivateSubnet1Id} ${PrivateSubnet2Id} --private-dns-enabled --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=rcarrata-EP-ec2}]'
```