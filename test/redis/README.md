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

# Additional Utilities 

Use **update_cluster_cert.py** and **create_redis_db.py** scripts to simplify configuration of the test environment. Please note that these utilities are meant for test environments only, to automate some of the steps in the instructions. For real environment values may need to be adjusted. Both scripts are using python requests library (Python version is 2.7.x), should be [installed](https://2.python-requests.org/en/master/user/install/) before executing the script

1. **update_cluster_cert.py** - Script to update certificates in target Redis Enterprise cluster. SSL key and certificate files needs to be be generated   separately (using openssl utility for an example). Redis Enterprise uses two type of certificates during the replication - proxy and syncer (see [Redis Enterprise documentation for details](https://docs.redislabs.com/latest/rs/administering/cluster-operations/updating-certificates/))

```
python update_cluster_cert.py <redis cluster url: https://HOST:Port> <cluster admin user> <cluster admin password> <key file> <certificate file> <type: proxy|syncer>
```
where all arguments are mandatory.

Example:
```
python update_cluster_cert.py https://redis-ent-cluster-redistest2.apps.mycluster.com admin@mydomain.com tGs555 /work/projects/ssl/redistest_proxy_key.pem /work/projects/ssl/redistest_proxy_cert.pem proxy`
```

2. **create_redis_db.py** - Script to create multiple Redis databases for 3scale application (non-persistent) based on values provided in config.file . Script capable of creating databases both on primary site and DR site (replicaOf)

```
python create_redis_db.py <Location of the config file> <Type of database to be created: primary|replica>
```

Update properties in config.file with particular values for specific environment. If databases are being created on primary site *SourceDB* section is not required. For primary site names of databases should be provided as comma-separated list without spaces(eg. *db1,db2,...*). For DR site *SourceDB* section should include parameters of the primary redis cluster and databases . Database names should be provided as a comma-separated set of pairs (*drdb1|db1*,*drdb2|db2*) split with "|" character. First value in each pair will be used to create redis database which is replicaOf of second value in a set

```
python create_redis_db.py test.config primary
```
