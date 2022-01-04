source /var/tmp/envs-ocp4
source /var/tmp/aws-resources

echo "Create a key pair for the bastion "
aws ec2 create-key-pair --key-name ocp4key --query 'KeyMaterial' --output text > ocp4key.pem
chmod 400 ocp4key.pem

echo "Bastion Storage"
cat > bastion-mapping.json << EODBastion
[
    {
       "DeviceName" : "/dev/sda1",
       "Ebs": { "VolumeSize" : 500, "DeleteOnTermination": false }
    }
]
EODBastion

echo "Create instance in Public Subnet, with Public Security group"
aws ec2 run-instances --image-id ${AMI_RHEL8} --count 1 --instance-type  t2.medium --key-name ocp4key --security-group-ids ${PublicSecurityGroupId} --block-device-mappings file://bastion-mapping.json --subnet-id ${PublicSubnetId} --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ocp4-public-bastion}]'
sleep 20
echo "Let the instance generate the IP"

IpPublicBastion=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=ocp4-public-bastion" | jq -r .Reservations[].Instances[].PublicIpAddress)
echo "export IpPublicBastion=$IpPublicBastion" >> ${LOGFILE}

IpPublicBastionPrivateIP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=ocp4-public-bastion" | jq -r .Reservations[].Instances[].PrivateIpAddress)
echo "export IpPublicBastionPrivateIP=$IpPublicBastionPrivateIP" >> ${LOGFILE}

echo "Launch private bastion interface"
aws ec2 run-instances --image-id ${AMI_RHEL8} --count 1 --instance-type  t2.medium --key-name ocp4key --security-group-ids ${PrivateSecurityGroup} --block-device-mappings file://bastion-mapping.json --subnet-id ${PrivateSubnet0Id} --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ocp4-private-bastion}]'
sleep 20
echo "Let the instance generate the IP"

IPPrivateBastion=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=ocp4-private-bastion" | jq -r .Reservations[].Instances[].PrivateIpAddress)
echo "export IPPrivateBastion=$IPPrivateBastion" >> ${LOGFILE}

sleep 120

