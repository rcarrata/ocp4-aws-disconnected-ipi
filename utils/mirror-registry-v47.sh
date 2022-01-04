#!/bin/bash

## Originally developed by Rafa Cardona - @rcardona
## Maintained by Roberto Carratala - @rcarrata

export OCP_RELEASE='4.9.11'
export OCP_VERSION='4.9'
export OCP_RELEASE_PATH='ocp'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export RELEASE_NAME='ocp-release'
export REGISTRY_PORT='5000'
export ARCHITECTURE='x86_64'
export REGISTRY_FQDN='bastion.asimov.lab'
export GODEBUG='x509ignoreCN=0'


usage() {
    echo " ---- Script Descrtipion ---- "
    echo "  "
    echo " This script configures the bastion host that is meant to serve as local registry and core installation components of Red Hat Openshift 4"
    echo " "
    echo " Pre-requisites: "
    echo " "
    echo " Download the OCP installation secret in https://cloud.redhat.com/openshift/install/pull-secret and create a file called 'redhat-registry-pullsecret.json' in the $HOME directory"
    echo " "

    echo " "
    echo " Options:  "
    echo " "
    echo " * prep_dependencies : installs the os packages needed to perform the registry installation on RHEL8"
    echo " * get_artifacts : downloads and prepare the oc client and OCP installation program"
    echo " * prep_registry : create and configures the local registry"
    echo " * mirror_registry : mirrors the core registry container images for installation locally"
    echo " * list_redhat-operators : Red Hat products packaged and shipped by Red Hat. Supported by Red Hat."
    echo " * list_certified-operators : Products from leading independent software vendors (ISVs)."
    echo " * list_redhat-marketplace : Certified software that can be purchased from Red Hat Marketplace."
    echo " * list_community-operators : Software maintained by relevant representatives in the operator-framework/community-operators GitHub repository. No official support."
    echo " * redhat-operators : Red Hat products packaged and shipped by Red Hat. Supported by Red Hat."
    echo " * certified-operators : Products from leading independent software vendors (ISVs)."
    echo " * redhat-marketplace : Certified software that can be purchased from Red Hat Marketplace."
    echo " * community-operators : Software maintained by relevant representatives in the operator-framework/community-operators GitHub repository. No official support."
    echo " * create-custom-catalog-redhat-operators : Red Hat products packaged and shipped by Red Hat. Supported by Red Hat."
    echo " * create-custom-catalog-certified-operators : Products from leading independent software vendors (ISVs)."
    echo " * create-custom-catalog-redhat-marketplace : Certified software that can be purchased from Red Hat Marketplace."
    echo " * create-custom-catalog-community-operators : Software maintained by relevant representatives in the operator-framework/community-operators GitHub repository. No official support."
    echo " * export-base-registry : Exports base container images for disconnected environments."
    echo " * export-custom-catalog-redhat-operators : Exports custom operator catalogs for disconnected environments."
    echo "  "
    echo -e " Usage: $0 [ prep_dependencies | get_artifacts | prep_registry | mirror_registry | list_redhat-operators | list_certified-operators | list_redhat-marketplace | list_community-operators | redhat-operators | certified-operators | redhat-marketplace | community-operators | create-custom-catalog-redhat-operators | create-custom-catalog-certified-operators | create-custom-catalog-redhat-marketplace | create-custom-catalog-community-operators ] "
    echo "  "
    echo " ---- Ends Descrtipion ---- "
    echo "  "
}


check_deps (){
    if [[ ! $(rpm -qa wget git bind-utils lvm2 lvm2-libs net-utils firewalld | wc -l) -ge 7 ]] ;
    then
        install_tools
    fi
}

get_artifacts() {
    cd ~/
    test -d artifacts || mkdir artifacts ; cd artifacts
    test -f openshift-client-linux-${OCP_RELEASE}.tar.gz  || curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/clients/${OCP_RELEASE_PATH}/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz
    test -f openshift-install-linux-${OCP_RELEASE}.tar.gz || curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/clients/${OCP_RELEASE_PATH}/${OCP_RELEASE}/openshift-install-linux-${OCP_RELEASE}.tar.gz
    test -f opm-linux-${OCP_RELEASE}.tar.gz || curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OCP_RELEASE}/opm-linux-${OCP_RELEASE}.tar.gz
    test -f grpcurl_1.8.0_linux_x86_64.tar.gz || curl -J -L -O https://github.com/fullstorydev/grpcurl/releases/download/v1.8.0/grpcurl_1.8.0_linux_x86_64.tar.gz
    cd ..
    prep_installer
}


install_tools() {
    #RHEL8
    if grep -q -i "release 8" /etc/redhat-release; then
        sudo dnf -y install libguestfs-tools podman skopeo httpd haproxy bind bind-utils net-tools nfs-utils rpcbind wget tree git lvm2 lvm2-libs firewalld jq
        sudo systemctl start firewalld
        echo -e "\e[1;32m Packages - Dependencies installed\e[0m"
    fi

    #RHEL7
    if grep -q -i "release 7" /etc/redhat-release; then
        #subscription-manager repos --enable rhel-7-server-extras-rpms
        sudo yum -y install libguestfs-tools podman skopeo httpd haproxy bind-utils net-tools nfs-utils rpcbind wget tree git lvm2.x86_64 lvm2-libs firewalld bind bind-utils || echo "Please - Enable rhel7-server-extras-rpms repo" && echo -e "\e[1;32m Packages - Dependencies installed\e[0m"
        sudo systemctl start firewalld
    fi
}

prep_registry () {
  echo -e ""
  echo -e "\e[1;32m Starting mirroring of registry OCP Version: ${OCP_RELEASE}\e[0m"
  echo -e ""
  sudo test -d /registry | sudo mkdir -p /registry/{auth,certs,data}
  sudo openssl req -newkey rsa:4096 -nodes -sha256 -keyout /registry/certs/domain.key -x509 -days 365 -subj "/CN=${REGISTRY_FQDN}" -out /registry/certs/domain.crt
  sudo cp -rf /registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
  sudo update-ca-trust
  echo "Please enter admin user password"
  sudo htpasswd -Bc /registry/auth/htpasswd admin
  sudo podman run -d --name mirror-registry --net host -v /registry/data:/var/lib/registry:z -v /registry/auth:/auth:z -e "REGISTRY_AUTH=htpasswd" -e "REGISTRY_AUTH_HTPASSWD_REALM=registry-realm" -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" -v /registry/certs:/certs:z -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key quay.io/redhat-emea-ssa-team/registry:2
}

prep_installer () {
    cd ~/
    echo "Uncompressing installer and client binaries"
    test -d ~/bin/ || mkdir ~/bin/
    sudo tar -xzf ./artifacts/openshift-client-linux-${OCP_RELEASE}.tar.gz  -C /usr/local/bin/
    sudo tar -xzf ./artifacts/openshift-install-linux-${OCP_RELEASE}.tar.gz -C /usr/local/bin/
    sudo tar -xzf ./artifacts/opm-linux-${OCP_RELEASE}.tar.gz -C /usr/local/bin/
    sudo tar -xzf ./artifacts/grpcurl_1.8.0_linux_x86_64.tar.gz -C /usr/local/bin/
    echo -e ""
    echo -e "\e[1;32m OCP Version Client $(oc version)\e[0m"
    echo -e ""
}

# MIRRORING BASE INSTALLATION REGISTRY

mirror_registry () {
  sudo podman generate systemd --name mirror-registry | sudo tee  /etc/systemd/system/mirror-registry.service
  sudo systemctl enable --now mirror-registry
  sudo firewall-cmd --permanent --add-port=${REGISTRY_PORT}/tcp
  sudo firewall-cmd --permanent --add-port=${REGISTRY_PORT}/udp
  sudo firewall-cmd --permanent --add-port=50051/tcp
  sudo firewall-cmd --permanent --add-port=50052/tcp
  sudo firewall-cmd --permanent --add-port=50053/tcp
  sudo firewall-cmd --permanent --add-port=50054/tcp
  sudo firewall-cmd --reload
  podman login --authfile ${HOME}/mirror-registry-pullsecret.json "${REGISTRY_FQDN}:${REGISTRY_PORT}"
  jq -s '{"auths": ( .[0].auths + .[1].auths ) }' ${HOME}/mirror-registry-pullsecret.json ${HOME}/redhat-registry-pullsecret.json > ${HOME}/bundle-pullsecret.txt
  oc adm -a ${HOME}/bundle-pullsecret.txt release mirror --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} --to=${REGISTRY_FQDN}:${REGISTRY_PORT}/${LOCAL_REPOSITORY} --to-release-image=${REGISTRY_FQDN}:${REGISTRY_PORT}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}
}

# MIRRORING DEAFULT CATALOG OPERATORS

redhat-operators () {

  echo "Mirror redhat-operators images "
  echo " "
  oc adm catalog mirror registry.redhat.io/redhat/redhat-operator-index:v4.7 ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm  --registry-config=${HOME}/bundle-pullsecret.txt --insecure --index-filter-by-os='linux/amd64'
  echo " "
}

certified-operators () {

  echo "Mirror certified-operators images"
  echo " "
  oc adm catalog mirror registry.redhat.io/redhat/certified-operator-index:v4.7 ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm --registry-config=${HOME}/bundle-pullsecret.txt --insecure --index-filter-by-os='linux/amd64'
  echo " "
}

redhat-marketplace () {

  echo "Mirror redhat-marketplace images"
  echo " "
  oc adm catalog mirror registry.redhat.io/redhat/redhat-marketplace-index:v4.7 ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm  --registry-config=${HOME}/bundle-pullsecret.txt --insecure --index-filter-by-os='linux/amd64'
  echo " "
}

community-operators () {

  echo "Mirror community-operators images"
  echo " "
  oc adm catalog mirror registry.redhat.io/redhat/community-operator-index:v4.7 ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm  --registry-config=${HOME}/bundle-pullsecret.txt --insecure--index-filter-by-os='linux/amd64'
  echo " "
}


# MIRRORING CUSTOM COTALOG OPERATORS

OPERATOR_NAMES="$2"

create-custom-redhat-operators () {
  if [[ -z "${OPERATOR_NAMES}" ]]
  then
    echo -e "\n\e[1;31m FAILED => Command expects custom images to be added to the custom Operator Catalog, please execute the command as follows: \e[0m"
    echo -e "\n\e[1;34m Command => mirror-registry-v47.sh create-custom-catalog-redhat-operators [OPERATOR_NAME_1, ...  ,OPERATOR_NAME_N] \e[0m"
    echo -e "\n\e[1;45m Example => mirror-registry-v47.sh create-custom-catalog-redhat-operators advanced-cluster-management,jaeger-product,quay-operator \e[0m"
    echo " "
    exit 1
  else
    echo -e "\n\e[1;32m Pruning custom-redhat-operators image \e[0m\n"
    opm index prune -f registry.redhat.io/redhat/redhat-operator-index:v4.7 -p ${OPERATOR_NAMES} -t ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-operators/redhat-operator-index:v4.7
    echo -e "\n\e[1;32m Pushing custom-redhat-operators image to local registry \e[0m\n"
    podman push ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-operators/redhat-operator-index:v4.7
    echo -e "\n\e[1;32m Creating custom-redhat-operators catalog \e[0m\n"
    oc adm catalog mirror ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-operators/redhat-operator-index:v4.7 ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-operators  -a ${HOME}/bundle-pullsecret.txt --insecure --index-filter-by-os='linux/amd64'
    if [[ $? -eq 0 ]]
    then
      echo -e "\n\e[1;32m STATUS: Custom redhat-operator SUCCESFUL CREATED => curl -u admin:admin https://${REGISTRY_FQDN}:${REGISTRY_PORT}/v2/olm-redhat-operators/tags/list | jq \e[0m"
    else
      echo -e "\n\e[1;31m STATUS: FAILED => Custom redhat-operator NOT CREATED \e[0m"
      exit 1
    fi
  fi
}

create-custom-certified-operators () {
  if [[ -z "${OPERATOR_NAMES}" ]]
  then
    echo -e "\n\e[1;31m FAILED => Command expects custom images to be added to the custom Operator Catalog, please execute the command as follows: \e[0m"
    echo -e "\n\e[1;34m Command => mirror-registry-v47.sh create-custom-catalog-certified-operators [OPERATOR_NAME_1, ...  ,OPERATOR_NAME_N] \e[0m"
    echo -e "\n\e[1;45m Example => mirror-registry-v47.sh create-custom-catalog-certified-operators cass-operator,dataset-operator,h2o-operator \e[0m"
    echo " "
    exit 1
  else
    echo -e "\n\e[1;32m Pruning custom-certified-operators image \e[0m\n"
    opm index prune -f registry.redhat.io/redhat/certified-operator-index:v4.7 -p ${OPERATOR_NAMES} -t ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-certified-operators/certified-operator-index:v4.7
    echo -e "\n\e[1;32m Pushing custom-certified-operators image to local registry \e[0m\n"
    podman push ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-certified-operators/certified-operator-index:v4.7
    echo -e "\n\e[1;32m Creating custom-certified-operators catalog \e[0m\n"
    oc adm catalog mirror ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-certified-operators/certified-operator-index:v4.7 ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-certified-operators -a ${HOME}/bundle-pullsecret.txt --insecure --index-filter-by-os='linux/amd64'
    if [[ $? -eq 0 ]]
    then
      echo -e "\n\e[1;32m STATUS: Custom certified-operators SUCCESFUL CREATED => curl -u admin:admin https://${REGISTRY_FQDN}:${REGISTRY_PORT}/v2/olm-certified-operators/tags/list | jq \e[0m"
    else
      echo -e "\n\e[1;31m STATUS: FAILED => Custom certified-operators NOT CREATED \e[0m"
      exit 1
    fi
  fi
}

create-custom-redhat-marketplace () {
  if [[ -z "${OPERATOR_NAMES}" ]]
  then
    echo -e "\n\e[1;31m FAILED => Command expects custom images to be added to the custom Operator Catalog, please execute the command as follows: \e[0m"
    echo -e "\n\e[1;34m Command => mirror-registry-v47.sh create-custom-catalog-redhat-marketplace [OPERATOR_NAME_1, ...  ,OPERATOR_NAME_N] \e[0m"
    echo -e "\n\e[1;45m Example => mirror-registry-v47.sh create-custom-catalog-redhat-marketplace cloudhedge-rhmp,instana-agent-rhmp,orca-rhmp \e[0m"
    echo " "
    exit 1
  else
    echo -e "\n\e[1;32m Pruning custom-redhat-marketplace image \e[0m\n"
    opm index prune -f registry.redhat.io/redhat/redhat-marketplace-index:v4.7 -p ${OPERATOR_NAMES} -t ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-marketplace/redhat-marketplace-index:v4.7
    echo -e "\n\e[1;32m Pushing custom-redhat-marketplace image to local registry \e[0m\n"
    podman push ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-marketplace/redhat-marketplace-index:v4.7
    echo -e "\n\e[1;32m Creating custom-redhat-marketplace catalog \e[0m\n"
    oc adm catalog mirror ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-marketplace/redhat-marketplace-index:v4.7 ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-marketplace  -a ${HOME}/bundle-pullsecret.txt --insecure --index-filter-by-os='linux/amd64'
    if [[ $? -eq 0 ]]
    then
      echo -e "\n\e[1;32m STATUS: Custom redhat-marketplace SUCCESFUL CREATED => curl -u admin:admin https://${REGISTRY_FQDN}:${REGISTRY_PORT}/v2/olm-redhat-marketplace/tags/list | jq \e[0m"
    else
      echo -e "\n\e[1;31m STATUS: FAILED => Custom redhat-marketplace NOT CREATED \e[0m"
      exit 1
    fi
  fi
}

create-custom-community-operators () {
  if [[ -z "${OPERATOR_NAMES}" ]]
  then
    echo -e "\n\e[1;31m FAILED => Command expects custom images to be added to the custom Operator Catalog, please execute the command as follows: \e[0m"
    echo -e "\n\e[1;34m Command => mirror-registry-v47.sh create-custom-catalog-community-operator [OPERATOR_NAME_1, ...  ,OPERATOR_NAME_N] \e[0m"
    echo -e "\n\e[1;45m Example => mirror-registry-v47.sh create-custom-catalog-community-operator cloudhedge-rhmp,instana-agent-rhmp,orca-rhmp \e[0m"
    echo " "
    exit 1
  else
    echo -e "\n\e[1;32m Pruning custom-community-operator image \e[0m\n"
    opm index prune -f registry.redhat.io/redhat/community-operator-index:v4.7 -p ${OPERATOR_NAMES} -t ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-community-operators/community-operator-index:v4.7
    echo -e "\n\e[1;32m Pushing custom-community-operator image to local registry \e[0m\n"
    podman push ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-community-operators/community-operator-index:v4.7
    echo -e "\n\e[1;32m Creating custom-community-operator catalog \e[0m\n"
    oc adm catalog mirror ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-community-operators/community-operator-index:v4.7 ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-community-operators  -a ${HOME}/bundle-pullsecret.txt --insecure --index-filter-by-os='linux/amd64'
    if [[ $? -eq 0 ]]
    then
      echo -e "\n\e[1;32m STATUS: Custom community-operators SUCCESFUL CREATED => curl -u admin:admin https://${REGISTRY_FQDN}:${REGISTRY_PORT}/v2/olm-community-operators/tags/list | jq \e[0m"
    else
      echo -e "\n\e[1;31m STATUS: FAILED => Custom community-operators NOT CREATED \e[0m"
      exit 1
    fi
  fi
}

# LISTING OPERATOR PACKAGES

list_packages_organization_redhat-operator () {
  if podman ps | grep redhat-operator
  then
    echo -e "\n\e[1;34m* Listing Operator Packages Organization:  \e[0m"
    echo -e "\n\e[1;35m   " - redhat-operator"  \e[0m"
    echo -e "\n\e[1;32m$(grpcurl -plaintext :50051 api.Registry/ListPackages | jq -r .name) \e[0m"
  else
    podman run -p50051:50051 -dt --name redhat-operator  registry.redhat.io/redhat/redhat-operator-index:v4.7
    echo -e "\n\e[1;34m* Listing Operator Packages Organization:  \e[0m"
    echo -e "\n\e[1;35m   " - redhat-operator"  \e[0m"
    echo -e "\n\e[1;32m$(grpcurl -plaintext :50051 api.Registry/ListPackages | jq -r .name) \e[0m"
  fi
}

list_packages_organization_certified-operators () {
  if podman ps | grep certified-operators
  then
    echo -e "\n\e[1;34m* Listing Operator Packages Organization:  \e[0m"
    echo -e "\n\e[1;35m   " - certified-operators"  \e[0m"
    echo -e "\n\e[1;32m$(grpcurl -plaintext :50052 api.Registry/ListPackages | jq -r .name) \e[0m"
  else
    podman run -p50052:50051 -dt --name certified-operators registry.redhat.io/redhat/certified-operator-index:v4.7
    echo -e "\n\e[1;34m* Listing Operator Packages Organization:  \e[0m"
    echo -e "\n\e[1;35m   " - certified-operators"  \e[0m"
    echo -e "\n\e[1;32m$(grpcurl -plaintext :50052 api.Registry/ListPackages | jq -r .name) \e[0m"
  fi
}

list_packages_organization_redhat-marketplace () {
  if podman ps | grep redhat-marketplace
  then
    echo -e "\n\e[1;34m* Listing Operator Packages Organization:  \e[0m"
    echo -e "\n\e[1;35m   " - redhat-marketplace"  \e[0m"
    echo -e "\n\e[1;32m$(grpcurl -plaintext :50053 api.Registry/ListPackages | jq -r .name) \e[0m"
  else
    podman run -p50053:50051 -dt --name redhat-marketplace registry.redhat.io/redhat/redhat-marketplace-index:v4.7
    echo -e "\n\e[1;34m* Listing Operator Packages Organization:  \e[0m"
    echo -e "\n\e[1;35m   " - redhat-marketplace"  \e[0m"
    echo -e "\n\e[1;32m$(grpcurl -plaintext :50053 api.Registry/ListPackages | jq -r .name) \e[0m"
  fi
}

list_packages_organization_community-operators () {
  if podman ps | grep community-operators
  then
    echo -e "\n\e[1;34m* Listing Operator Packages Organization:  \e[0m"
    echo -e "\n\e[1;35m   " - community-operators"  \e[0m"
    echo -e "\n\e[1;32m$(grpcurl -plaintext :50054 api.Registry/ListPackages | jq -r .name) \e[0m"
  else
    podman run -p50054:50051 -dt --name community-operators registry.redhat.io/redhat/community-operator-index:v4.7
    echo -e "\n\e[1;34m* Listing Operator Packages Organization:  \e[0m"
    echo -e "\n\e[1;35m   " - community-operators"  \e[0m"
    echo -e "\n\e[1;32m$(grpcurl -plaintext :50054 api.Registry/ListPackages | jq -r .name) \e[0m"
  fi
}

export-base-registry () {
    cd ${HOME}

    echo -e "\n\e[1;32m Starting mirroring base images for OCP v${OCP_RELEASE} \e[0m"
    echo -e "\n\e[1;32m This operation may take up to 20 min depending on the network speed \e[0m\n"
    mkdir -p ${HOME}/mirror-${OCP_RELEASE}
    oc adm release mirror -a ${HOME}/bundle-pullsecret.txt --to-dir=${HOME}/mirror-base-${OCP_RELEASE} quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE}
    if [[ $? -eq 0 ]]
    then
      echo -e "\n\e[1;34m* Base images for OCP v${OCP_RELEASE} susscesfully mirrored to directory: \e[0m"
      echo -e "\n  \e[1;45m$(ls -d ${HOME}/mirror-base-${OCP_RELEASE}) \e[0m\n"
    else
      echo -e "\n\e[1;31m* FAILED => Mirroring base images for OCP v${OCP_RELEASE} \e[0m"
      rm -rf mirror-base-${OCP_RELEASE}
      echo " "
      exit 1
    fi

    echo -e "\n\e[1;32m Starting compressing ${HOME}/mirror-base-${OCP_RELEASE} \e[0m\n"
    tar -zcvf mirror-base-${OCP_RELEASE}.tar.gz mirror-base-${OCP_RELEASE}
    if [[ $? -eq 0 ]]
    then
      echo -e "\n\e[1;34m* Tar file containing base images for OCP v${OCP_RELEASE} \e[0m"
      echo -e "\n  \e[1;45m$(ls -sh ${HOME}/mirror-base-${OCP_RELEASE}.tar.gz) \e[0m\n"
      rm -rf mirror-base-${OCP_RELEASE}
    else
      echo -e "\n\e[1;31m* FAILED => export-base-registry \e[0m"
      rm -rf mirror-base-${OCP_RELEASE}
      echo " "
      exit 1
    fi
}

mirror-custom-catalog-redhat-operators () {
  if [[ -z "${OPERATOR_NAMES}" ]]
  then
    echo -e "\n\e[1;31m FAILED => Command expects custom images to be added to the custom Operator Catalog, please execute the command as follows: \e[0m"
    echo -e "\n\e[1;34m Command => ./mirror-registry-v47.sh export-custom-catalog-redhat-operators [OPERATOR_NAME_1, ...  ,OPERATOR_NAME_N] \e[0m"
    echo -e "\n\e[1;45m Example => ./mirror-registry-v47.sh export-custom-catalog-redhat-operators advanced-cluster-management,jaeger-product,quay-operator \e[0m"
    echo " "
    exit 1
  else
    echo -e "\n\e[1;32m Pruning custom-redhat-operators image \e[0m\n"
    opm index prune -f registry.redhat.io/redhat/redhat-operator-index:v4.7 -p ${OPERATOR_NAMES} -t ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-operators/redhat-operator-index:v4.7
    echo -e "\n\e[1;32m Pushing custom-redhat-operators image to local registry \e[0m\n"
    podman push ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-operators/redhat-operator-index:v4.7
    echo -e "\n\e[1;32m Mirroring custom-redhat-operators catalog to file mirror-redhat-operators-${OCP_RELEASE} \e[0m\n"
    cd ${HOME}
    oc adm catalog mirror -a ${HOME}/bundle-pullsecret.txt ${REGISTRY_FQDN}:${REGISTRY_PORT}/olm-redhat-operators/redhat-operator-index:v4.7 file://mirror-redhat-operators-${OCP_RELEASE} --insecure
    if [[ $? -eq 0 ]]
    then
      echo -e "\n\e[1;32m STATUS: Mirroring redhat-operator SUCCESFUL DONE => ls -d ${HOME}/v2/mirror-redhat-operators-${OCP_RELEASE} \e[0m"
    else
      echo -e "\n\e[1;31m STATUS: FAILED => Mirroring mirror-redhat-operators-${OCP_RELEASE} NOT DONE \e[0m"
      exit 1
    fi
    echo -e "\n\e[1;32m Compressing mirror-redhat-operators-${OCP_RELEASE} file \e[0m\n"
    tar czvf mirror-redhat-operators-${OCP_RELEASE}.tar.gz v2
    if [[ $? -eq 0 ]]
    then
      echo -e "\n\e[1;32m STATUS: mirror-redhat-operators-${OCP_RELEASE} SUCCESFUL compressed => ls -sh ${HOME}/mirror-redhat-operators-${OCP_RELEASE}.tar.gz \e[0m"
      rm -rf ${HOME}/mirror-redhat-operators-${OCP_RELEASE}
    else
      echo -e "\n\e[1;31m STATUS: FAILED => Compressing mirror-redhat-operators-${OCP_RELEASE} NOT DONE \e[0m"
      exit 1
    fi
  fi
}

# MENU OPTIONS

key="$1"

case $key in
    get_artifacts)
        get_artifacts
        ;;
    mirror_registry)
        mirror_registry
        ;;
    prep_registry)
        prep_registry
        ;;
    prep_dependencies)
        install_tools
        ;;
    redhat-operators)
        redhat-operators
        ;;
    certified-operators)
        certified-operators
        ;;
    redhat-marketplace)
        redhat-marketplace
        ;;
    community-operators)
        community-operators
        ;;
    create-custom-catalog-redhat-operators)
        create-custom-redhat-operators
        ;;
    create-custom-catalog-certified-operators)
        create-custom-certified-operators
        ;;
    create-custom-catalog-redhat-marketplace)
        create-custom-redhat-marketplace
        ;;
    create-custom-catalog-community-operators)
        create-custom-community-operators
        ;;
    list_redhat-operators)
        list_packages_organization_redhat-operator
        ;;
    list_certified-operators)
        list_packages_organization_certified-operators
        ;;
    list_redhat-marketplace)
        list_packages_organization_redhat-marketplace
        ;;
    list_community-operators)
        list_packages_organization_community-operators
        ;;
    export-base-registry)
	export-base-registry
	      ;;
    export-custom-catalog-redhat-operators)
        mirror-custom-catalog-redhat-operators
	      ;;
    *)
        usage
        ;;
esac
