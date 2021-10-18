### 6 - Install OCP4 Disconnected


```
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""

export PULL_SECRET=$( cat /root/bundle-pullsecret.txt | jq -c . )
export SSH_KEY=$(cat $HOME/.ssh/id_rsa.pub)
export CERTIFICATE=$(cat /registry/certs/domain.crt | sed -e 's/^/     /')

cat > install-config.yaml << EOF
apiVersion: v1
baseDomain: ${PrivateHostedZone}
proxy:
  httpProxy: http://${IpProxy}:3128
  httpsProxy: http://${IpProxy}:3128 
  noProxy: localhost
controlPlane:
  hyperthreading: Enabled
  name: master
  platform:
    aws:
      zones:
      - ${AvailabilityZone0}
      - ${AvailabilityZone1}
      - ${AvailabilityZone2}
      type: m5.xlarge
  replicas: 3
compute:
- hyperthreading: Enabled
  name: worker
  platform:
    aws:
      type: m5.xlarge
      zones:
      - ${AvailabilityZone0}
      - ${AvailabilityZone1}
      - ${AvailabilityZone2}
  replicas: 3
metadata:
  name: ocp4-dis
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineCIDR: ${VpcCidr}
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: ${REGION}
    subnets: 
    - ${PrivateSubnet0Id}
    - ${PrivateSubnet1Id}
    - ${PrivateSubnet2Id}
pullSecret: |
  ${PULL_SECRET}
fips: false
sshKey: |
  ${SSH_KEY}
publish: Internal
additionalTrustBundle: |
${CERTIFICATE}
imageContentSources:
- mirrors:
  - bastion.${PrivateHostedZone}:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - bastion.${PrivateHostedZone}:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF
```

```
GODEBUG=x509ignoreCN=0 oc adm release extract -a /root/bundle-pullsecret.txt --command=openshift-install "bastion.${PrivateHostedZone}:5000/ocp4/openshift4:${OCP_RELEASE}-${ARCHITECTURE}"
sudo cp -pr openshift-install /usr/local/bin/
sudo mv openshift-install /tmp
openshift-install version 
```

```
mkdir ocp4-dir
cp -rf install-config.yaml ocp4-dir/install-config.yaml
```

```
openshift-install --dir=ocp4-dir create cluster --log-level=debug
```

## (Optional) Only in Passthrough mode - Only for SCP limitations

```
grep credentialsMode install-config.yaml
credentialsMode: Passthrough
```

## (Optional) Only in Manual Mode - Only for SCP limitations

```
openshift/99_openshift-ingress-operator_cloud-credentials-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloud-credentials
  namespace: openshift-ingress-operator
data:
  aws_access_key_id:  <base64-encoded-access-key-id>
  aws_secret_access_key: <base64-encoded-secret-access-key>
```