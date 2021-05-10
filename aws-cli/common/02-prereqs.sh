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