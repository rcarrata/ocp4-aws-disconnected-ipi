# 8 - IPI Disconnected - Post Install Disconnected tasks

* Disable the Proxy the Cluster

```
$ oc edit proxy/cluster
apiVersion: config.openshift.io/v1
kind: Proxy
metadata:
  name: cluster
spec: {}
status: {}
```

* Disabling the default OperatorHub sources

```
oc patch OperatorHub cluster --type json \
    -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

* Apply the CatalogSource and the imageContentSourcePolicy:

```
oc apply -f ocp4-dir/manifests-redhat-operator-index-xxxx/catalogSource.yaml
oc apply -f manifests-redhat-operator-index-xxxx/imageContentSourcePolicy.yaml
```

## Disable Cloud Credential Operator

```sh
oc edit cm cloud-credential-operator-config
...
data:
  disabled: "true"
```

TODO: Check the Manual instead of disable:

```sh
oc patch cloudcredentials cluster -n openshift-cloud-credential-operator --type json -p '[{ "op": "replace", "path": "/spec/credentialsMode", "value": "Manual" }]'
```

## Scale the cluster to see if the Operators works towards AWS

sh```
MACHINESET=$(oc get machineset -n openshift-machine-api --no-headers=true | head -n1 | cut -f1 -d" " )

oc scale --replicas=2 -n openshift-machine-api machineset $MACHINESET
```