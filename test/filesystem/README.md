# 3scale-dr - Scripts and templates to replicate content of the filesystem in pod on remote OCP cluster

Some of the components of 3scale API platform are using RWX PVC backed filesystem to store artifacts from embedded CMS. In cases when corresponding volumes cannot be replicated to DR site on storage level oc rsync mechanism combined with kubernetes cronjobs can be used to synchronize content of the filesystem directly from the pod   

## Using or building oc client image

Image is built with CentOS v7 image as a base with security updates installed.Version oc client is 3.11.0. Use published image (also used in templates by default)

```docker
docker pull quay.io/mmikhail/oc-centos7:latest
```

or update Dockerfile if needed and build your own : 

- Pull current git repository 
- Navigate to test/filesystem/docker directory 
- build image `docker build -t oc-centos7:latest .`

## Create system account on source system 

While standard userid (see templates with userid/password) can be used to connect to pod on primary OpenShift cluster, preferred way is to create abd use system account in particular project with limited permissions. To create role and system account 

- Login to primary OpenShift cluster 
- Switch to 3scale project, in our case it is try-3scale 
- Use src-rbac-template.yaml template to create Role/System Account/RoleBindigns (RSH_SYSTEM_ACCOUNT can be updated with desired account name,by default it is dr-filesystem-repl)

    ```
    oc process -f src-rbac-template.yaml |oc apply -f -
    ```

    or
   ```
    oc process -f src-rbac-template.yaml -p RSH_SYSTEM_ACCOUNT=my-favorite-account-name |oc apply -f -
    ```

Once system account has been created retrieve security token as it will be used in next step (as part of system account creation process OpenShift will create corresponding secrets),eg.

```
oc get `oc get secret -o NAME|grep dr-filesystem-repl-token|head -1` -o jsonpath='{.data.token}{"\n"}' |base64 -d;echo
```

## Configuring and running scheduled job on target OpenShift cluster 

Note that replication cronjob will require secret and imagestream objects to be created in corresponding OpenShift project on target site (DR OCP cluster)

1 - Create secret object in the project (in test environment it will be try-3scale) 

```
oc create secret generic oc-client --from-literal=URL="https://source.ocpcluster.url"  --from-literal=AuthToken="eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJ0cnktM3NjYWxlIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImRyLWZpbGVzeXN0ZW0tcmVwbGljYXRpb24tdG9rZW4tcWhsN2ciLCJrdWJlcm6ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZHItZmlsZXN5c3RlbS1yZXBsaWNhdGlvbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImI1ZWZkNmM1LTZhYWQtMTFlOS04YjE5LWJlZWZmZWVkMDAzMCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDp0cnktM3NjYWxlOmRyLWZpbGVzeXN0ZW0tcmVwbGljYXRpb24ifQ.yXAqvuAS-mwiqypuFlOIdP5td32Fjj2Rj7BKACjiJwu1G54UdM1HWZ5kC4FVx_8XPzgjgeduna7pOJi45HJVURl_Waov1gNNgaErjmrSgt8Azjxqk1Je3swXJC9xpLOk7GMaQZjETOjdZBscg62uQ59kcdccBjcPlwywrqsXGIe2C9LaBhwWzmfEDd3fJAgIl-lWBee4FQ_vtW-b7DDYvAe1VKCtJKl0urkTTruAqtpQJrtxDa_p9YvdG0NPsMJV0yAPHNVJ1OD-Psufh_3YJ3mKRfkv-O9SqbZjlBS7DOpIyDnqd8bVwv8xXD-lycAILdsp5xMegt2aHn3DqPJNDg"
```

where 

> URL      - primary OCP cluster URL that is being used by oc client

> AuthToken- token for system account created in previous section 

2 - Using template `trgt-oc-client-image-template.yaml` create image stream to pull image with oc client see [Using or building oc client image] (#using-or-building-oc-client-image) section

```
oc process -f trgt-oc-client-image-template.yaml |oc apply -f -
```
following parameters can be updated and passed in command line

>OC_IMAGE_TAG - oc client version (by default 0.1.1)

>OC_CLIENT_IMAGE - name and repo for the image (default:quay.io/mmikhail/oc-centos7)

3 - Create kubernetes [cronjob](https://docs.openshift.com/container-platform/3.11/dev_guide/cron_jobs.html) to enable filesystem synchronization based on particular schedule

```
oc process -f trgt-cronjob-template.yaml -p PVC_NAME=system-storage -p RSYNC_JOB_SCHEDULE=""*/1 * * * *" -p SOURCE_PROJECT_NAME=try-3scale|oc apply -f -
```
where 

>PVC_NAME - name of the PVC claim that will be used to back target filesystem (default: temp-pvc)

>RSYNC_JOB_SCHEDULE - schedule when rsync will run in [cron format](https://en.wikipedia.org/wiki/Cron) (default: every minute, eg. */1 * * * *)

>SOURCE_PROJECT_NAME - project name on primary OpenShift cluster where source pod is running (default: try-3scale)

>SOURCE_POD_PREFIX - the beginning of the pod name on primary OCP cluster that correspond to deployment object that was used to initiate the pod (default: system-sidekiq)

>SOURCE_DIR - filesystem on source pod , doesn't require to be changed unless process is being used for something that is not 3scale related (default: /opt/system/public/system/)


