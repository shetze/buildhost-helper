#!/bin/bash -x

# Publish the content view(s) and promote if necessary
#
# This script can be tested /used with a command like:
#   PUSH_USER=jenkins SATELLITE=sat6.example.com \
#   RSA_ID=/var/lib/jenkins/.ssh/id_rsa TESTVM_ENV=2 CV="cv-acme-soe-demo" \
#   CV_PASSIVE_LIST="cv-passive-1,cv-passive-2" ORG=Default_Organization \
#   CCV_NAME_PATTERN="ccv-test-*" BUILD_URL=$$ ./publishcv.sh

# Load common parameter variables
. $(dirname "${0}")/common.sh

# Create an array from all the content view names
IFS=',' CV_LIST=( ${CV} ${CV_PASSIVE_LIST} )

for cv in "${CV_LIST[@]}"
do
    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
	    "hammer content-view publish --name \"${cv}\" --organization \"${ORG}\" --description \"Build ${BUILD_URL}\"" || \
		{ err "Content view '${cv}' couldn't be published."; exit 1; }

    # get the latest version of each CV, add it to the array
    VER_ID_LIST+=( "$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
	"hammer content-view info --name \"${cv}\" --organization \"${ORG}\" \
	| grep \"ID:\" | tail -1 | tr -d ' ' | cut -f2 -d ':'")" )
done

# sleep after publishing content view to give chance for locks to get cleared up
sleep 90

if [[ -n ${CCV_NAME_PATTERN} ]]
then # we want to update and publish all CCVs containing our CVs

    # Create a sed script to replace old with new version ID
    for (( i = 0; i < ${#CV_LIST[@]}; i++ ))
    do
        cv=${CV_LIST[$i]}
        ver_id=${VER_ID_LIST[$i]}

        CV_VER_SED+="$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer --csv content-view version list --content-view \"${cv}\" --organization \"${ORG}\"" | awk -F',' -v ver_id="${ver_id}" '
                $1 != "ID" && $1 != ver_id {ids="s/," $1 ",/," ver_id ",/;" ids}
                END {print ids}')"
    done

    # Create an array of composite content view IDs matching the given pattern
    CCV_TMP_IDS=( $(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer --csv content-view list --organization \"${ORG}\" --search \"${CCV_NAME_PATTERN}\"" | awk -F, '$1 ~ /^[0-9]+$/ {print $1}') )

    # We need at the same time to find out which of the CCVs use the given CV
    # as well as keep the ID of all other used CV versions, but filter out
    # the currently used version of our CV, to avoid two versions of the same CV
    for ccv_id in ${CCV_TMP_IDS[@]}
    do
	cv_tmp_ver_ids=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer --output yaml content-view info --id ${ccv_id} --organization \"${ORG}\"" \
	    | awk -F': *' '
	        $1 == "Components" {cmp = 1; next}
	        {if (!cmp) next}
	        /^[A-Z]/ {cmp = 0; next}
	        $1 ~ / *ID/ { ids=$2 "," ids; }
	        END {print "," ids}')
        cv_used_ver_ids=$(echo "${cv_tmp_ver_ids}" | sed "${CV_VER_SED}")
        if [[ "${cv_used_ver_ids}" != "${cv_tmp_ver_ids}" ]]
        then # the CCV really uses one of the given CVs in any version
            CCV_IDS+=( ${ccv_id} )
            CV_USED_VER_IDS+=( "${cv_used_ver_ids}" )
        fi
    done
fi

# We update the found CCVs with the new version and publish them
if [[ ${#CCV_IDS[*]} -gt 0 ]]
then # there is at least one CCV using the given CVs
    for (( i = 0; i < ${#CCV_IDS[@]}; i++ ))
    do
            ccv_id=${CCV_IDS[$i]}
            cv_used_ver_ids=${CV_USED_VER_IDS[$i]}

            # we add back the CV under its latest version to the CCV
	    ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
                "hammer content-view update --id ${ccv_id} --component-ids \"${cv_used_ver_ids}\" --organization \"${ORG}\"" || \
	            { err "CCV '${ccv_id}' couldn't be updated with '${cv_used_ver_ids}'."; exit 1; }

            # sleep after updating CV for locks to get cleared up
            sleep 10

            # And then we publish the updated CCV
            ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
                "hammer content-view publish --id \"${ccv_id}\" --organization \"${ORG}\" --description \"Build ${BUILD_URL}\"" || \
	            { err "CCV '${ccv_id}' couldn't be published."; exit 1; }
    done
fi

if [[ -n ${TESTVM_ENV} ]]
then
    for (( i = 0; i < ${#CV_LIST[@]}; i++ ))
    do # promote the latest version of each CV
        cv=${CV_LIST[$i]}
        ver_id=${VER_ID_LIST[$i]}

        ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer content-view version promote --content-view \"${cv}\" --organization \"${ORG}\" \
        --to-lifecycle-environment-id \"${TESTVM_ENV}\" --id ${ver_id}"
    done

    # we also promote the latest version of each CCV
    for ccv_id in ${CCV_IDS[@]}
    do
        ccv_ver=$(ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
            "hammer --csv content-view version list --content-view-id ${ccv_id} --organization \"${ORG}\"" | awk -F',' '$1 ~ /^[0-9]+$/ {if ($3 > maxver) {maxver = $3; maxid = $1} } END {print maxid}')
        ssh -l ${PUSH_USER} -i ${RSA_ID} ${SATELLITE} \
        "hammer content-view version promote --content-view-id \"${ccv_id}\" --organization \"${ORG}\" \
        --to-lifecycle-environment-id \"${TESTVM_ENV}\" --id ${ccv_ver}"
    done
fi
