## Prerequisites

### Automated

```
bash -x 01-setup.sh
```

### Manual

1. Set up the environment variables

```
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
echo REGION=eu-west-1 >> envs-ocp4
export REGION=eu-west-1
echo s3Endpoint="com.amazonaws.${REGION}.s3" >> envs-ocp4
echo elbEndpoint="com.amazonaws.${REGION}.elasticloadbalancing" >> envs-ocp4
echo ec2Endpoint="com.amazonaws.${REGION}.ec2" >> envs-ocp4
echo LOGFILE=aws-resources >> envs-ocp4
echo OCP_RELEASE=4.7.5 >> envs-ocp4
echo ARCHITECTURE=x86_64 >> envs-ocp4
echo AMI_RHEL8="ami-04facb3ed127a2eb6" >> envs-ocp4
```

### Automated

```
bash -x 02-prereqs.sh
```

### Manual

2. Set up AWS cli

We set up aws cli locally on the client machine, in this case laptop, to create the infrastructure on AWS step by step

```
source envs-ocp4

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