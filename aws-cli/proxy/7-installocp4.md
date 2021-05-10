
* configure install-config.yaml

mind the publish: Internal
mind, even if docs seem to imply there is no need to configure a https proxy in case it is the same as the http proxy, tests showed updates are not working. So configure both proxies, even if they are the same!

export IpProxy="bastion.${PrivateHostedZone}"

```
bastion# cat > install-config.yaml << EOF
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
  name: aws-ipi-proxy
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineCIDR: 10.0.0.0/16
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
```

17. test proxy server

login to bastion and from there to the test server in one of the private networks and validate proxy is working

vm created earlier in priv subnet: 10.0.3.153
proxy server: 10.0.3.153:3128

From public bastion server

```
bastion# IpPublicBastion=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=rcarrata-public-bastion" | jq -r .Reservations[].Instances[].PublicIpAddress)

$ ssh -i ocpkey.pem ec2-user@$IPPrivateBastion
Last login: Mon Mar 29 21:29:46 2021 from 10.0.3.153
```

```
$ export http_proxy=http://10.0.3.153:3128
[ec2-user@ip-10-0-0-66 ~]$ export https_proxy=$http_proxy
```

```
$ curl www.google.es -v
* Rebuilt URL to: www.google.es/
*   Trying 74.125.193.94...
* TCP_NODELAY set
*   Trying 2a00:1450:400b:c01::5e...
```

```
$ curl www.google.es -vI
* Rebuilt URL to: www.google.es/
* Uses proxy env variable http_proxy == 'http://10.0.3.153:3128'
*   Trying 10.0.3.153...
* TCP_NODELAY set
* Connected to 10.0.3.153 (10.0.3.153) port 3128 (#0)
> HEAD http://www.google.es/ HTTP/1.1
> Host: www.google.es
> User-Agent: curl/7.61.1
> Accept: */*
> Proxy-Connection: Keep-Alive
>
< HTTP/1.1 200 OK
HTTP/1.1 200 OK

$ logout 
```

18. deploy Openshift4

```
mkdir ~/cluster
cp install-config.yaml ~/cluster
openshift-install create cluster --dir=./cluster --log-level debug
```

at this point the cluster is deployed and we can login and validate the cluster (see below)

in case it times out at this stage as not all operators are coming up (aut, ingress,..) we can still login via export KUBECONFIG=/home/ec2-user/cluster/auth/kubeconfig and check what is going on. You might want to check if worker nodes have been created and if not, check ec32 and loadbalancer endpoints

19. Check your cluster

```
$ oc get nodes

$ oc get machineset -n openshift-machine-api

$ oc get machines -n openshift-machine-api
```

