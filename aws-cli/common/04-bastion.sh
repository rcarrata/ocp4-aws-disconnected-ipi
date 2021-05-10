source envs-ocp4
source aws-resources

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
aws ec2 run-instances --image-id ${AMI_RHEL8} --count 1 --instance-type  t2.medium --key-name ocp4key --security-group-ids ${PublicSecurityGroupId} --block-device-mappings file://bastion-mapping.json --subnet-id ${PublicSubnetId} --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rcarrata-public-bastion}]'

IpPublicBastion=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=rcarrata-public-bastion" | jq -r .Reservations[].Instances[].PublicIpAddress)
echo "export IpPublicBastion=$IpPublicBastion" >> ${LOGFILE}

IpPublicBastionPrivateIP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=rcarrata-public-bastion" | jq -r .Reservations[].Instances[].PrivateIpAddress)
echo "export IpPublicBastionPrivateIP=$IpPublicBastionPrivateIP" >> ${LOGFILE}


echo "Launch private bastion interface"
aws ec2 run-instances --image-id ${AMI_RHEL8} --count 1 --instance-type  t2.medium --key-name ocp4key --security-group-ids ${PrivateSecurityGroup} --block-device-mappings file://bastion-mapping.json --subnet-id ${PrivateSubnet0Id} --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rcarrata-private-bastion}]'

IPPrivateBastion=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=rcarrata-private-bastion" | jq -r .Reservations[].Instances[].PrivateIpAddress)
echo "export IPPrivateBastion=$IPPrivateBastion" >> ${LOGFILE}

sleep 120

