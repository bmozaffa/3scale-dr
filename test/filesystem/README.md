# 3scale-dr - Create test Redis Enterprise Cluster in OpenShift 

Templates in this repository are based on https://github.com/RedisLabs/redis-enterprise-k8s-docs and were adjusted to facilitate specific deployment scenario for DR test. 
Deployment steps are based on instructions from  https://redislabs.com/blog/install-redis-enterprise-clusters-using-operators-openshift/ article. 

In order to perform initial setup for Redis Enterprise Cluster execute  following steps: 


1- Create a new project:

`oc new-project redistest`

2- Execute bash script 

`create_redis_cluster.sh redistest`

To prevent unintentional execution in wrong OpenShift project script will validate if project specified as argument is the same as currently selected in oc client.

**Note:** By default script will create cluster without persistent storage. If persistent storage is required modify following lines in the script


>\#Create cluster with persistent storage

>redis_cluster=${CLUSTER_NAME}.yaml

>\#Create cluster without persistence 

>\#redis_cluster=${CLUSTER_NAME}-nopersist.yaml``
