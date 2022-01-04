# 9 - Optional Configuration for Post Cluster Startup

Optional Configurations for apply after the installation finished

## Manually Update Wildcard Records

You will need to figure out the IP of the LB that is created as a result of the Service with type: LoadBalancer that ingress creates and update the records to point to it. In a disconnected private cluster, the IP for the private zone will need to be the IP of the LB interface on the subnet so that nodes can reach it (as opposed to the external LB name/address),

## Disconnected: Disable Insights-Operator

The Insights Operator is part of the remote health reporting functionality of the cluster which also includes the Telemetry Operator.  Disabling both of these operators is accomplished by  modifying the global cluster pull secret for remote health reporting.

Instructions to disable the Telemetry and Insights Operators can be found in the Option out of [remote health reporting documentation](https://docs.openshift.com/container-platform/latest/support/remote_health_monitoring/opting-out-of-remote-health-reporting.html).

## Disconnected: Disable Samples-Operator

Samples Operator can be disabled by setting the managementState configuration parameter to Removed.  When this is set the Samples Operator will remove the set of managed image streams and templates in the OpenSift namespace.  

For more information on this setting please refer to the [Samples Operator Configuration Parameters documentation](https://docs.openshift.com/container-platform/latest/openshift_images/configuring-samples-operator.html#samples-operator-configuration_configuring-samples-operator).

## Only in Passthrough mode - Only for SCP limitations

```sh
grep credentialsMode install-config.yaml
credentialsMode: Passthrough
```

## Only in Manual Mode - Only for SCP limitations 

TODO: test this without proxy and the SGs with PrivateSubnets

```sh
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
