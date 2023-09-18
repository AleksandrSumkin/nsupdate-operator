#!/usr/bin/env bash

if [[ $1 == "--config" ]] ; then
  cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: v1
  kind: Node
  executeHookOnEvent:
  - Added
  - Deleted
  - Modified
EOF
else
  type=$(jq -r '.[0].type' ${BINDING_CONTEXT_PATH})
  if [[ $type == "Event" ]] ; then
    echo "Got Event: "
    jq '.[0].object' ${BINDING_CONTEXT_PATH}

    hostName=$(jq -r '.[0].object.status.addresses[] | select(.type=="Hostname") | .address' $BINDING_CONTEXT_PATH)
    internalIP=$(jq -r '.[0].object.status.addresses[] | select(.type=="InternalIP") | .address' $BINDING_CONTEXT_PATH)
    
    echo "Node '${hostName}' with IP '${internalIP}' is catched!"

    #podName=$(jq -r '.[0].object.metadata.name' $BINDING_CONTEXT_PATH)
    #echo "Pod '${podName}' added"
  fi
fi
