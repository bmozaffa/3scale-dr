#!/bin/bash

############################################################################################
#
#  Script to login to OpenShift cluster and rsync directory from pod using pod name prefix 
#  Script require OC_URL, OC_AUTH_TOKEN or OC_USERID/OC_PASSWORD to be defined before
#  executing script . Use OC_AUTH_TOKEN in cases when system account is being used to access 
#  OpenShift cluster 
#  Usage: oc_rsync <SOURCE_PROJECT_NAME> <POD_NAME prefix> <SOURCE_PATH> <TARGET_PATH>
#
############################################################################################# 


PROGNAME=$(basename $0)

get_timestampt ()
{
  return `date +%Y-%m-%dT%H-%M-%S`
}
error_exit()
{
  if [ "${2}" != "0" ]; then

        echo "`date +%Y-%m-%dT%H-%M-%S`:${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        exit ${2}
  fi
}

print_usage()
  {
     echo "Usage: ${PROGNAME}  <SOURCE_PROJECT_NAME> <POD_NAME prefix> <SOURCE_PATH> <TARGET_PATH>"
     exit 1
  }

# Reset return code to 0
ret=0

# Check environment variables 

if [ -z ${OC_URL:+x} ]; then 
  ret=99;  error_exit "ERROR:$LINENO:environment variable OC_URL is not set" ${ret}
fi 
if [ ! -z ${OC_AUTH_TOKEN:+x} ]; then
  echo "`date +%Y-%m-%dT%H-%M-%S`:INFO:OC_AUTH_TOKEN variable is set "
  if [ ! -z "${OC_USERID:+x}" -o ! -z "${OC_PASSWORD:+x}" ]; then
    ret=99; error_exit "ERROR:$LINENO:If OC_AUTH_TOKEN is set OC_USERID and OC_PASSWORD should be unset. Only one type of authentication to OpenShift is supported" ${ret}
  fi
  LOGIN_TOKEN_ENABLED=1
else
  LOGIN_TOKEN_ENABLED=0
  if [ -z "${OC_USERID:+x}" ]; then 
    ret=99;  error_exit "ERROR:$LINENO:environment variable OC_USERID is not set" ${ret}
  fi 
  if [ -z "${OC_PASSWORD:+x}" ]; then 
    ret=99;  error_exit "ERROR:$LINENO:environment variable OC_PASSWORD is not set" ${ret}
  fi
fi
if [ -z "${1}" ]; then
  echo "ERROR: all arguments are mandatory.SOURCE_PROJECT_NAME is missing ";print_usage
else
  OC_PROJECTNAME=${1}
fi  
if [ -z "${1}" ]; then
  echo "ERROR: all arguments are mandatory.SOURCE_PROJECT_NAME is missing ";print_usage
else
  OC_PROJECTNAME=${1}
fi 
if [ -z "${2}" ]; then
  echo "ERROR: all arguments are mandatory POD_NAME prefix is missing ";print_usage
else
  OC_SOURCE_PODNAME_PREFIX=${2}
fi 
if [ -z "${3}" ]; then
  echo "ERROR: all arguments are mandatory.SOURCE_PATH is missing ";print_usage
else
  OC_SOURCE_PATH=${3}
fi 
if [ -z "${4}" ]; then
  echo "ERROR: all arguments are mandatory.TARGET_PATH is missing ";print_usage
else
  OC_TARGET_PATH=${4}
fi 

# Login to Source OpenShift Cluster

if [ ${LOGIN_TOKEN_ENABLED} == 1 ]; then
  echo "`date +%Y-%m-%dT%H-%M-%S`:INFO:Connecting to OpenShift cluster ${OC_URL} using token"

  oc login ${OC_URL} --token=${OC_AUTH_TOKEN} --insecure-skip-tls-verify=true 2>$1
  ret=$? ; error_exit "ERROR:$LINENO:login to target OpenShift cluster has failed" ${ret}
else
  echo "`date +%Y-%m-%dT%H-%M-%S`:INFO:Connecting to OpenShift cluster ${OC_URL} using userdid ${OC_USERID}"
  oc login ${OC_URL} --username=${OC_USERID} --password=${OC_PASSWORD} --insecure-skip-tls-verify=true
  ret=$? ; error_exit "ERROR:$LINENO:login to target OpenShift cluster has failed" ${ret}

  echo "`date +%Y-%m-%dT%H-%M-%S`:Switching to project ${OC_PROJECTNAME} "
  oc project ${OC_PROJECTNAME}
  ret=$? ; error_exit "ERROR:$LINENO:Project ${OC_PROJECTNAME} doesn't exist or you don't have access to it" ${ret}
fi
echo "`date +%Y-%m-%dT%H-%M-%S`:Rsync with pod in project ${OC_PROJECTNAME} " 
oc rsync  `oc get pods -o NAME -n ${OC_PROJECTNAME} |egrep "^pod\/${OC_SOURCE_PODNAME_PREFIX}"`:${OC_SOURCE_PATH} ${OC_TARGET_PATH} -n ${OC_PROJECTNAME} 2>&1
ret=$? ; error_exit "ERROR:$LINENO:Rsync command has failed" ${ret}