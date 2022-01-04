## Prerequisites

### 0 - Clone the repository

```
git clone https://github.com/rcarrata/ocp4-aws-disconnected-ipi.git
cd ocp4-aws-disconnected-ipi/aws-cli
```

### 1.1 - Set up Environment Variables - Automated

```
bash -x 01-setup.sh
```

### 1.2 - Set up Environment Variables - Manual

1. Set up the environment variables

```
echo customer=rcarrata > /var/tmp/envs-ocp4
echo PrivateHostedZone="asimov.lab" >> /var/tmp/envs-ocp4
echo VpcCidr="10.0.0.0/16" >> /var/tmp/envs-ocp4
echo Subnet0Cidr="10.0.0.0/24" >> /var/tmp/envs-ocp4
echo Subnet1Cidr="10.0.1.0/24" >> /var/tmp/envs-ocp4
echo Subnet2Cidr="10.0.2.0/24" >> /var/tmp/envs-ocp4
echo DNSServerIp="10.0.3.10" >> /var/tmp/envs-ocp4
echo SubnetPublicCidr="10.0.3.0/24" >> /var/tmp/envs-ocp4
echo AvailabilityZone0="eu-west-1a" >> /var/tmp/envs-ocp4
echo AvailabilityZone1="eu-west-1b" >> /var/tmp/envs-ocp4
echo AvailabilityZone2="eu-west-1c" >> /var/tmp/envs-ocp4
echo AWSKEY="TO_CHANGE" >> /var/tmp/envs-ocp4
echo AWSSECRETKEY="TO_CHANGE" >> /var/tmp/envs-ocp4
echo REGION=eu-west-1 >> /var/tmp/envs-ocp4
export REGION=eu-west-1
echo s3Endpoint="com.amazonaws.${REGION}.s3" >> /var/tmp/envs-ocp4
echo elbEndpoint="com.amazonaws.${REGION}.elasticloadbalancing" >> /var/tmp/envs-ocp4
echo ec2Endpoint="com.amazonaws.${REGION}.ec2" >> /var/tmp/envs-ocp4
echo LOGFILE=/var/tmp/aws-resources >> /var/tmp/envs-ocp4
echo OCP_RELEASE=4.7.5 >> /var/tmp/envs-ocp4
echo ARCHITECTURE=x86_64 >> /var/tmp/envs-ocp4
echo AMI_RHEL8="ami-04facb3ed127a2eb6" >> /var/tmp/envs-ocp4
```

### 2.1 Set up AWS CLI - Automated

```
bash -x 02-prereqs.sh
```

### 2.2 Set up AWS CLI - Manual

We set up aws cli locally on the client machine, in this case laptop, to create the infrastructure on AWS step by step

```
source /var/tmp/envs-ocp4

curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"

unzip awscli-bundle.zip

./awscli-bundle/install -i /usr/local/aws -b /bin/aws

/bin/aws --version

mkdir $HOME/.aws

cat << EOF > $HOME/.aws/credentials
[default]
aws_access_key_id = ${AWSKEY}
aws_secret_access_key = ${AWSSECRETKEY}
region = $REGION
EOF

aws sts get-caller-identity

touch ${LOGFILE}
echo "#Openshift 4 Install AWS Resources" > ${LOGFILE}
```
