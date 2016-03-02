#!/bin/bash 

# Push RPMs to satellite via a yum repo
#
# e.g. ${WORKSPACE}/scripts/rpmpush.sh ${WORKSPACE}/buildhost-packages
#

# Load common parameter variables
. $(dirname "${0}")/common.sh

if [[ -z "$1" ]] || [[ ! -d "$1" ]]
then
    usage "$0 <artefacts directory>"
    exit ${NOARGS}
fi
workdir=$1

# refresh the upstream yum repo
createrepo ${YUM_REPO}
    
# use hammer to push the RPMs into the repo
/usr/bin/hammer repository synchronize --organization "${ORG}" --product "${PRODUCT}" --name "${YUM_REPO_NAME}" 2>/dev/null

