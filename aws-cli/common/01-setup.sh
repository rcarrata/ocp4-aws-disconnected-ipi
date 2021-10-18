echo customer=rcarrata > envs-ocp4
echo PrivateHostedZone="asimov.lab" >> envs-ocp4
echo VpcCidr="10.0.0.0/16" >> envs-ocp4
echo Subnet0Cidr="10.0.0.0/24" >> envs-ocp4
echo Subnet1Cidr="10.0.1.0/24" >> envs-ocp4
echo Subnet2Cidr="10.0.2.0/24" >> envs-ocp4
echo DNSServerIp="10.0.3.10" >> envs-ocp4
echo SubnetPublicCidr="10.0.3.0/24" >> envs-ocp4
echo AvailabilityZone0="eu-west-1a" >> envs-ocp4
echo AvailabilityZone1="eu-west-1b" >> envs-ocp4
echo AvailabilityZone2="eu-west-1c" >> envs-ocp4
echo AWSKEY= <redacted> >> envs-ocp4
echo AWSSECRETKEY= <redacted> >> envs-ocp4
export REGION=eu-west-1
echo REGION=eu-west-1 >> envs-ocp4
echo s3Endpoint="com.amazonaws.${REGION}.s3" >> envs-ocp4
echo elbEndpoint="com.amazonaws.${REGION}.elasticloadbalancing" >> envs-ocp4
echo ec2Endpoint="com.amazonaws.${REGION}.ec2" >> envs-ocp4
echo LOGFILE=aws-resources >> envs-ocp4
echo OCP_RELEASE=4.8.2 >> envs-ocp4
echo ARCHITECTURE=x86_64 >> envs-ocp4
export IpProxy="bastion.${PrivateHostedZone}"
IpProxy="bastion.${PrivateHostedZone}" >> envs-ocp4
