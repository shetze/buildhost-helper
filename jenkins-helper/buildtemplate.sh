#!/bin/bash

# Instruct Foreman to rebuild the test VMs
#
# e.g ${WORKSPACE}/scripts/buildtestvms.sh 'test'
#
# this will tell Foreman to rebuild all machines in hostgroup TESTVM_HOSTGROUP

# Load common parameter variables
. $(dirname "${0}")/common.sh

if [[ -z ${PUSH_USER} ]] || [[ -z ${SATELLITE} ]]  || [[ -z ${RSA_ID} ]] \
   || [[ -z ${ORG} ]] || [[ -z ${TEMPLATE_VM} ]]
then
    err "Environment variable PUSH_USER, SATELLITE, RSA_ID, ORG " \
        "or TEMPLATE_VM not set or not found."
    exit ${WORKSPACE_ERR}
fi

# rebuild test VMs
for host in $TEMPLATE_VM
do
    info "Rebuilding VM Name $host"
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer host update --name $host --build yes"

    _STATUS=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} "hammer host status --name $host" | grep Power | cut -f2 -d: | tr -d ' ')
    if [[ ${_STATUS} == 'running' ]] || [[ ${_STATUS} == 'up' ]]
    then
        ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host reboot --name $host"
    elif [[ ${_STATUS} == 'shutoff' ]] || [[ ${_STATUS} == 'down' ]]
    then
        ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer host start --name $host"
    else
        err "Host $host is neither running nor shutoff. No action possible!"
        exit 1
    fi
done

