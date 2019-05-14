#!/bin/bash

PROGNAME=$(basename $0)

error_exit()
{
  if [[ "${2}" != "0" ]]; then

        echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        exit ${2}
  fi
}

print_usage()
  {
     echo "Usage: ${PROGNAME}  <project name>"
     exit 1
  }

if [ $# -lt 1 ]; then
  print_usage
fi 

if [ -z $1 ]; then
  print_usage 
else
  PROJECT_NAME=${1}
  CURRENT_PROJECT=`oc project|cut -d '"' -f2`
  if [ ${PROJECT_NAME} != ${CURRENT_PROJECT} ]; then
    echo "You currently not using project ${PROJECT_NAME}. Please use command oc project ${PROJECT_NAME} to switch to correct openshift project. Exiting..."
    exit 1
  fi
fi

echo "Redis Operator will be installed in project: ${CURRENT_PROJECT}"
read -p "Continue [Y]? " -n 1 -r
if [[ ! $REPLY =~ ^[Y]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

echo ">>> Apply SCC"
ret=0
oc apply -f scc.yaml
ret=$? ; error_exit "ERROR:$LINENO:scc.yaml processing has failed" ${ret}
oc adm policy add-scc-to-group redis-enterprise-scc system:serviceaccounts:${PROJECT_NAME}
ret=$? ; error_exit "ERROR:$LINENO:Applying Security context to setvice account ${PROJECT_NAME} processing has failed" ${ret}

# Use or not to use persistence for Redis DB. redis-ent-cluster hardcoded name of the operator

#Name of redis cluster 
CLUSTER_NAME=redis-ent-cluster

#Create cluster with persistent storage
#redis_cluster=${CLUSTER_NAME}.yaml

#Create cluster without persistence 
redis_cluster=${CLUSTER_NAME}-nopersist.yaml

# Processing of following templates is the same , using loop instead of individual commands

for templ in rbac.yaml sb_rbac.yaml crd.yaml operator_rhel.yaml ${redis_cluster}; do
  echo ">>> Apply $templ"
  oc apply -f ${templ}
  ret=$? ; error_exit "ERROR:$LINENO:${templ} processing has failed" ${ret}
done

#Additional steps not covered by standard RedisLabs setup : create route for Redis Admin UI and API 

# As all objects may not been created at this point, will wait for 12 sec 
counter=1;
while [ ${counter} -le  4 ]
do 
  if [ `oc get service ${CLUSTER_NAME}-ui -o jsonpath='{.metadata.name}'` = "${CLUSTER_NAME}-ui" ]; 
  then 
    echo ">>> Service has been created" 
    break 
  fi
  echo ">>> Waiting for another 10 sec for service ${CLUSTER_NAME}-ui to be created,be patient..."
  sleep 3
  counter=$(($counter+1))
done
echo ">>>Oh well, route may needs to be created manually after all project objects have been created...."



echo ">>> Creating route for Redis Admin UI >>>>"
oc expose service ${CLUSTER_NAME}-ui
ret=$? ; error_exit "ERROR:$LINENO:Cannot create route as service has not been created yet." ${ret}

#Set tls policy as a passthrough 
oc patch route ${CLUSTER_NAME}-ui -p '{"spec":{"tls": { "termination": "passthrough" }}}' 
ret=$? ; error_exit "ERROR:$LINENO:Cannot update tls settings for the route" ${ret}

echo ">>> Completed . Use https://`oc get route ${CLUSTER_NAME}-ui -o jsonpath='{.spec.host}'` to administer Redis Enterprise Cluster"
