# 3scale-dr
Repo for assets under development to support 3scale DR

To run 3scale with databases and redis defined within template in mw lab:

1- Create a new project:

`oc new-project example`

2- Link image puller secret:

`oc secrets link default imagestreamsecret --for=pull`

3- Use this template with a unique domain name that can be resolved and other required parameters:

`oc new-app -f amp_postgres.yml -p WILDCARD_DOMAIN=example.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p ADMIN_PASSWORD=password -p MASTER_PASSWORD=password -p WILDCARD_POLICY=Subdomain -p SYSTEM_DATABASE_PASSWORD=password -p ZYNC_DATABASE_PASSWORD=password -p SYSTEM_BACKEND_PASSWORD=SYSTEM_BACKEND_PASSWORD -p SYSTEM_BACKEND_SHARED_SECRET=SYSTEM_BACKEND_SHARED_SECRET -p SYSTEM_APP_SECRET_KEY_BASE=SYSTEM_APP_SECRET_KEY_BASE -p ADMIN_PASSWORD=ADMIN_PASSWORD -p ADMIN_ACCESS_TOKEN=ADMIN_ACCESS_TOKEN -p MASTER_PASSWORD=MASTER_PASSWORD -p MASTER_ACCESS_TOKEN=MASTER_ACCESS_TOKEN -p SYSTEM_DATABASE_PASSWORD=SYSTEM_DATABASE_PASSWORD -p ZYNC_DATABASE_PASSWORD=ZYNC_DATABASE_PASSWORD -p ZYNC_SECRET_KEY_BASE=ZYNC_SECRET_KEY_BASE -p ZYNC_AUTHENTICATION_TOKEN=ZYNC_AUTHENTICATION_TOKEN -p APICAST_ACCESS_TOKEN=APICAST_ACCESS_TOKEN`

To use Crunchy instead of Postgresql, also set required environment variables including PG_MODE and similar. The image stream would need to come back and be referenced, instead of the one from openshift.