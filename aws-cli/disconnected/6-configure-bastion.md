
16. Configure bastion

set up aws cli, ocp related/needed tools to maintain and deploy ocp as well as a very simple proxy

* Login to bastion in public network

```
ssh -i ocp4key.pem $IpPublicBastion -l ec2-user
sudo -i
cp -pr /home/ec2-user/ocp4key.pem .
cp -pr /home/ec2-user/envs-ocp4 .
cp -pr /home/ec2-user/aws-resources .
yum install vim git wget bind-utils -y
echo "PATH=\$PATH:/usr/local/bin" >> ~/.bashrc
bash
source envs-ocp4
source aws-resources
```

* Add the AWS credentials

```
mkdir ~/.aws/
cat << EOF >> $HOME/.aws/credentials
[default]
aws_access_key_id = ${AWSKEY}
aws_secret_access_key = ${AWSSECRETKEY}
region = $REGION
EOF
```

* Check the DNS of Route53 generated before:

```
dig bastion.${PrivateHostedZone} +short
```

```
wget https://raw.githubusercontent.com/rcarrata/ocp4-aws-disconnected-ipi/main/utils/mirror-registry-v47.sh
chmod u+x mirror-registry-v47.sh
```

* Install the necessary software for continue

```
./mirror-registry-v47.sh prep_dependencies
```

NOTE: substitute the REGISTRY_FQDN for our own FQDN

```
touch redhat-registry-pullsecret.json
vim redhat-registry-pullsecret.json
```

* Install ocp and opm tools: 

```
 ./mirror-registry-v47.sh get_artifacts
```

* Prepare the registry:

```
bash -x mirror-registry-v47.sh prep_registry
```

* Login to the local registry and redhat registry:

```
podman login registry.redhat.io
podman login bastion.asimov.lab:5000
```

* Mirror Registry of the Base Packages for the installation:

```
bash -x mirror-registry-v47.sh mirror_registry
```

```
curl -u admin:admin -X GET https://bastion.asimov.lab:5000/v2/_catalog
curl -u admin:admin -X GET https://bastion.asimov.lab:5000/v2/ocp4/openshift4/tags/list?n=1000 | jq
```

* List the redhat operators needed for mirror and to use with OLM:

```
bash -x mirror-registry-v47.sh list_redhat-operators
```

* Red Hat products packaged and shipped by Red Hat. Supported by Red Hat:

```
bash -x mirror-registry-v47.sh create-custom-catalog-redhat-operators quay-operator
```

```
curl -u admin:admin -X GET https://bastion.asimov.lab:5000/v2/_catalog | jq -r .
```


17. Set up the Proxy (only for the installation)

NOTE: verify this with other installs

* login to bastion in public network


```
alternatives --set python /usr/bin/python3
yum install -y firewalld squid vim wget unzip openssl python3 bind-utils
```

* enable FW and enable squid ports

```
systemctl enable firewalld --now
firewall-cmd --add-port=3128/tcp --permanent
firewall-cmd --add-port=3128/tcp
```

* set up simple squid configuration 

```
cp /etc/squid/squid.conf /etc/squid/squid.conf.orig
cp utils/squid.conf /etc/squid/squid.conf

systemctl enable squid --now

systemctl status squid
```