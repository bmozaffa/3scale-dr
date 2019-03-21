# 3scale-dr
Repo for assets under development to support 3scale DR

To run 3scale with databases and redis defined within template in mw lab:

1- Create a new project:

`oc new-project example`

2- Link image puller secret:

`oc secrets link default imagestreamsecret --for=pull`

3- Use this template with a unique domain name that can be resolved and other required parameters:

`oc new-app -f amp_postgres.yml -p WILDCARD_DOMAIN=example.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p ADMIN_PASSWORD=password -p MASTER_PASSWORD=password -p WILDCARD_POLICY=Subdomain -p SYSTEM_DATABASE_PASSWORD=password -p ZYNC_DATABASE_PASSWORD=password`

To use Crunchy instead of Postgresql, also set required environment variables including PG_MODE and similar. The image stream would need to come back and be referenced, instead of the one from openshift.