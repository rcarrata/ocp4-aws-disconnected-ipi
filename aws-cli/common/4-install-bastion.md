## Launch Bastion for Disconnected

### Automated

```
bash -x 04-bastion.sh
```

### Manual

14. launch Public bastion instance

bastion instance (RHEL8) which will be publicly accessible via ssh and we configure proxy on later

* Create a key pair for the bastion 

```
aws ec2 create-key-pair --key-name ocp4key --query 'KeyMaterial' --output text > ocp4key.pem
chmod 400 ocp4key.pem
```

* Identify the AMI


AMI RHEL8 in eu-west-1: ami-04facb3ed127a2eb6

```
export AMI_RHEL8="ami-04facb3ed127a2eb6"
```

* Bastion Mapping 

```
cat > bastion-mapping.json << EODBastion
[
    {
       "DeviceName" : "/dev/sda1",
       "Ebs": { "VolumeSize" : 500, "DeleteOnTermination": false }
    },
]
EODBastion
```

* Create instance in Public Subnet, with Public Security group and 

```
aws ec2 run-instances --image-id ${AMI_RHEL8} --count 1 --instance-type  t2.medium --key-name ocp4key --security-group-ids ${PublicSecurityGroupId} --block-device-mappings file://bastion-mapping.json --subnet-id ${PublicSubnetId} --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rcarrata-public-bastion}]'

IpPublicBastion=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=rcarrata-public-bastion" | jq -r .Reservations[].Instances[].PublicIpAddress)
echo "export IpPublicBastion=$IpPublicBastion" >> ${LOGFILE}
```

15. Launch private bastion interface

```
aws ec2 run-instances --image-id ${AMI_RHEL8} --count 1 --instance-type  t2.medium --key-name ocp4key --security-group-ids ${PrivateSecurityGroup} --block-device-mappings file://bastion-mapping.json --subnet-id ${PrivateSubnet0Id} --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rcarrata-private-bastion}]'

IPPrivateBastion=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=rcarrata-private-bastion" | jq -r .Reservations[].Instances[].PrivateIpAddress)
echo "export IPPrivateBastion=$IPPrivateBastion" >> ${LOGFILE}
```


