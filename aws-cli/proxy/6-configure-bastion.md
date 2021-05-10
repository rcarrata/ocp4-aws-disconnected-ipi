## Bastion


16. Configure bastion

set up aws cli, ocp related/needed tools to maintain and deploy ocp as well as a very simple proxy

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

* Install aws cli / ocp tools

```
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /bin/aws
/bin/aws --version
wget -qO - https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz | tar xfz -
 -C /usr/bin/
wget -qO - https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz | tar xfz - -C /usr/bin/

openshift-install version
```

* configure aws tools as well on bastion as ec2 user

```
mkdir ~/.aws/
export AWSKEY=<redacted>
export AWSSECRETKEY=<redacted>
export REGION=eu-west-1
cat << EOF >> $HOME/.aws/credentials
[default]
aws_access_key_id = ${AWSKEY}
aws_secret_access_key = ${AWSSECRETKEY}
region = $REGION
EOF
aws sts get-caller-identity
```

* create ssh key (basically follow docs)

```
# ssh-keygen -t rsa -b 2048 -N '' -f ~/.ssh/id_rsa
```

* check ip for proxy

```
IpProxy=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
echo $IpProxy
```