# IPI Installation - Mode Disconnected

This is the AirGapped mode with no public Internet connectivity from the cluster is allowed.
Mirrored Images in Bastion are needed and used for the installation of OpenShift Cluster as well as the several operators.

## Diagram Disconnected Installation

<img align="center" width="950" src="pics/disconnected.png">

The following items are not required or created when you install a disconnected cluster:

* A BaseDomainResourceGroup, since the cluster does not create public records
* Public IP addresses
* Public DNS records
* Public endpoints
* Internet facing Load balancers

Not a [Virtual Private Endpoint](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview) is available for this internal VNET <-> Azure Resource Manager connection

For this reason a Azure Firewall, ONLY allowing the connections to Azure Resource Manager (but with the public DNS as management.azure.com) and denying the rest of the connections to Internet (or Quay.io)
Mirrored Images in the Bastion are used for this scenario, due to not external connectivity is allowed.


## Automation for deploy the Disconnected OpenShift cluster

### With AWS-CLI

* [6. Configure Bastion](../aws-cli/disconnected/6-configure-bastion.md)
* [7. Install OCP4 Disconnected](../aws-cli/disconnected/7-installocp4disconnected.md)
* [8. Post Install OCP4](../aws-cli/disconnected/8-post-install.md)
* [9. Optional](../aws-cli/disconnected/9-optional.md)
