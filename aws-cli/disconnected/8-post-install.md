## Post Install

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
oc apply -f manifests-redhat-operator-index-xxxx/catalogSource.yaml
oc apply -f manifests-redhat-operator-index-xxxx/imageContentSourcePolicy.yaml
```