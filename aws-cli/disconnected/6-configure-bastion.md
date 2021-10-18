
16. Configure bastion

set up aws cli, ocp related/needed tools to maintain and deploy ocp as well as a very simple proxy

* Login to bastion in public network

```bash
ssh -i ocp4key.pem $IpPublicBastion -l ec2-user
sudo -i
sudo cp -pr /home/ec2-user/ocp4key.pem .
sudo cp -pr /home/ec2-user/envs-ocp4 .
sudo cp -pr /home/ec2-user/aws-resources .
yum install vim git wget bind-utils -y
echo "PATH=\$PATH:/usr/local/bin" >> ~/.bashrc
bash
source envs-ocp4
source aws-resources
```

* Add the AWS credentials

```bash
mkdir ~/.aws/
cat << EOF >> $HOME/.aws/credentials
[default]
aws_access_key_id = ${AWSKEY}
aws_secret_access_key = ${AWSSECRETKEY}
region = $REGION
EOF
```

* Check the DNS of Route53 generated before:

```bash
dig bastion.${PrivateHostedZone} +short
```

```bash
wget https://raw.githubusercontent.com/rcarrata/ocp4-aws-disconnected-ipi/main/utils/mirror-registry-v47.sh
chmod u+x mirror-registry-v47.sh
```

* Install the necessary software for continue

```bash
./mirror-registry-v47.sh prep_dependencies
```

NOTE: substitute the REGISTRY_FQDN for our own FQDN

```bash
touch redhat-registry-pullsecret.json
vim redhat-registry-pullsecret.json
```

* Install ocp and opm tools: 

```bash
 ./mirror-registry-v47.sh get_artifacts
```

* Prepare the registry (set up admin as password):

```bash
bash -x mirror-registry-v47.sh prep_registry
```

* Login to the local registry and redhat registry:

```bash
podman login registry.redhat.io

export GODEBUG=x509ignoreCN=0
podman login bastion.asimov.lab:5000
```

NOTE: Default admin / "admin" as passwords in the bastion

* Mirror Registry of the Base Packages for the installation:

```bash
bash -x mirror-registry-v47.sh mirror_registry
```

```bash
curl -u admin:admin -X GET https://bastion.asimov.lab:5000/v2/_catalog
curl -u admin:admin -X GET https://bastion.asimov.lab:5000/v2/ocp4/openshift4/tags/list?n=1000 | jq
```

* List the redhat operators needed for mirror and to use with OLM:

```bash
bash -x mirror-registry-v47.sh list_redhat-operators
```

* Red Hat products packaged and shipped by Red Hat. Supported by Red Hat:

```bash
bash -x mirror-registry-v47.sh create-custom-catalog-redhat-operators quay-operator
```

```bash
curl -u admin:admin -X GET https://bastion.asimov.lab:5000/v2/_catalog | jq -r .
```

17. Set up the Proxy (only for the installation)

IMPORTANT: As explained in the following [bugzilla](https://bugzilla.redhat.com/show_bug.cgi?id=1743483#c40) the disconnected install on aws would be that if user drop the overall internet traffic capacity (no way to access AWS APIs), user need enable proxy to allow those AWS APIs access, add those api endpoints into proxy's whitelist.

* login to bastion in public network

```bash
alternatives --set python /usr/bin/python3
yum install -y firewalld squid vim wget unzip openssl python3 bind-utils
```

* enable FW and enable squid ports

```bash
systemctl enable firewalld --now
firewall-cmd --add-port=3128/tcp --permanent
firewall-cmd --add-port=3128/tcp
```

* set up simple squid configuration

```bash
git clone https://github.com/rcarrata/ocp4-aws-disconnected-ipi.git
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.orig
sudo cp ocp4-aws-disconnected-ipi/utils/squid.conf /etc/squid/squid.conf

systemctl enable squid --now

systemctl status squid
```