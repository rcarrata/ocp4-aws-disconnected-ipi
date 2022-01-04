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

IMPORTANT: As explained in the following [bugzilla](https://bugzilla.redhat.com/show_bug.cgi?id=1743483#c40) the disconnected install on aws would be that if user drop the overall internet traffic capacity (no way to access AWS APIs), user need enable proxy to allow those AWS APIs access, add those api endpoints into proxy's whitelist.

The proxy is ONLY used during the installation of the cluster, and afterwards it's disabled, isolating the cluster to internet connections.

## Automation for deploy the Disconnected OpenShift cluster

### With AWS-CLI

* [6. Configure Bastion](../aws-cli/disconnected/6-configure-bastion.md)
* [7. Install OCP4 Disconnected](../aws-cli/disconnected/7-installocp4disconnected.md)
* [8. Post Install OCP4](../aws-cli/disconnected/8-post-install.md)
* [9. Optional](../aws-cli/disconnected/9-optional.md)
