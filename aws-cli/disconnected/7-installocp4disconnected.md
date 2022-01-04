# 7 - IPI Disconnected - Install OCP4 Disconnected

* Add the install-config.yaml customized:

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

* Generate the openshift-install for the disconnected installation:

```bash
GODEBUG=x509ignoreCN=0 oc adm release extract -a /root/bundle-pullsecret.txt --command=openshift-install "bastion.${PrivateHostedZone}:5000/ocp4/openshift4:${OCP_RELEASE}-${ARCHITECTURE}"
sudo cp -pr openshift-install /usr/local/bin/
sudo mv openshift-install /tmp
openshift-install version 
```

* Copy the install-config.yaml to a directory for the installation:

```bash
mkdir ocp4-dir
cp -rf install-config.yaml ocp4-dir/install-config.yaml
```

* Create the OpenShift cluster with the dir generated before:

```bash
openshift-install --dir=ocp4-dir create cluster --log-level=debug
```

* Login into the Openshift Cluster and check the operators:

```bash
 export KUBECONFIG=ocp4-dir/auth/kubeconfig
 oc get co
```
