#!/bin/bash 

# Push Puppet Modules to satellite via a Pulp repo
#
# e.g. ${WORKSPACE}/scripts/puppetpush.sh 
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]
then
    err "PUSH_USER or SATELLITE not set or not found"
    exit ${WORKSPACE_ERR}
fi

# Refresh the PULP_MANIFEST
cd ${PUPPET_REPO}
rm PULP_MANIFEST
touch PULP_MANIFEST
for I in *.tar.gz
do
    size=$(du -b ${I} | awk '{print $1}')
    sha256=$(sha256sum ${I} | awk '{print $1}')
    echo "${I},${sha256},${size}" >> PULP_MANIFEST
done

    
    
# use hammer on the satellite to push the modules into the repo
ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
    "hammer repository synchronize --id ${PUPPET_REPO_ID}"

if [[ -z "${CV}" ]]
then
    info "Variable 'CV' empty, no need to attach new modules."
    exit 0
fi

exit 0
