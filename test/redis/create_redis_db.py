import sys
import getopt
import requests
import json
import re
import ConfigParser


DRY_RUN=0

#Print usage 
def usage():
    print "Creating sample Redis Enterprise databases for 3scale API platform"
    print "Usage: python create_redis_db.py <Location of the config file> <Type of database to be created: primary|replica>"

#Makes API call to Redis Enterprise Cluster and creates new database based on provided arguments 
def create_database(url, auth_token, cert_strings, db_pass, db_name, db_type, primary_url=None, primary_cert=None ):

    tls_sni=None

    if db_type=="primary":
        post_data={
            "name": db_name,
            "type": "redis",
            "authentication_redis_pass": db_pass,
            "memory_size": 214748365,
            "tls_mode": "replica_ssl",
            "authentication_ssl_client_certs": [
            {
                "client_cert": cert_strings
            }
            ]
        }
    elif db_type=="replica":
        print "Replica"
        if primary_url is None or primary_cert is None:
            print "ERROR: both primary Redis URL and Primary certificate are required parameters when replica database is selected"
            exit(1)
        try:
            tls_sni=re.search("@(.+?):", primary_url).group(1)
            print tls_sni
        except AttributeError:
            print "ERROR: Primary Redis URL is mallformed"
            exit(1)
        post_data={
            "name": db_name,
            "type": "redis",
            "authentication_redis_pass": db_pass,
            "memory_size": 214748365,
            "tls_mode": "replica_ssl",
            "authentication_ssl_client_certs": [
                {
                    "client_cert": cert_strings
                }
            ],
            "replica_sync": "enabled",   
            "replica_sources": [
                {
                    "server_cert": primary_cert,
                    "encryption": True,
                    "uri": primary_url,
                    "replication_tls_sni": tls_sni,
                    "compression": 0    
                }
            ]
        }
    else:
        print "ERROR:Wrong DB type parameter"
        exit(1)
    if DRY_RUN:
        print json.dumps(post_data, sort_keys=False, indent=2)
    else:
        try:
            response=requests.post(url, auth=auth_token, json=post_data ,verify=False)       
        except Exception as ex:
            print "ERROR:Failed to create database with error" ,ex
        else:
            print (response.json())

# Creates list out of string using , as separator
def convert_to_list(db_names):
    li=list(db_names.split(","))
    return li

#Opens certificate or key file in pem format and converts it to single line string with \n characters included
def get_cert_string(cert_file):

    try:
        with open(cert_file) as f:
            out = '\n'.join(line.strip() for line in f)
    except FileNotFoundError as ex:
        print "ERROR: Couldn't open file, Exception:",ex 
        exit()
    else:
        return out

#parses json response from Redis API and returns name, uid and authentication as a dictionary object
def get_dict_by_dbname(response):

    value_dict={}
    for item in response:
        value_dict[item['name']]=[item['uid'],item['authentication_admin_pass']]
    return value_dict

# Gets about all Redis Enterprise databases configured in the cluster . Returns json 
def get_db_config(url, user, password):

    auth_token=(user,password)
    try:
        response=requests.get(url, auth=auth_token, verify=False)       
    except Exception as ex:
        print "ERROR:Failed to create database with error" ,ex
    else:
        return (response.json())

def main(argv):


    src_db_data={}
    dbnames=None

    config = ConfigParser.RawConfigParser()

    if len(argv)!=2:
        usage()
        exit(1)
    
    try:
        config.read(argv[0])
    except Exception as ex:
        print "ERROR: Can not read file argv[0]", ex
        exit (1)

    db_type=argv[1]
    trgt_db_url=config.get('TargetDB','clusterurl')+'/v1/bdbs'
    trgt_auth_values=(config.get('TargetDB','adminuser'),config.get('TargetDB','adminpassword'))
    trgt_db_userpass=config.get('TargetDB','userpassword')
    trgt_client_cert=get_cert_string(config.get('TargetDB','certfilename'))

    dbnames=config.get('Common','databases')

    if db_type=="replica":
        try:
            src_db_url=config.get('SourceDB','clusterurl')+'/v1/bdbs'
            src_db_user=config.get('SourceDB','adminuser')
            src_db_password=config.get('SourceDB','password')
            src_db_domain=config.get('SourceDB','domain')
            src_db_data=get_dict_by_dbname(get_db_config(src_db_url, src_db_user, src_db_password))
            src_primary_cert=get_cert_string(config.get('SourceDB','certfilename'))

        except ConfigParser.NoSectionError as ex:
            print "ERROR:", ex
            exit(1)
         
    for db in convert_to_list(dbnames):
        if db_type=='replica':
            splitdbs=db.split('|')
            src_db_name=splitdbs[1]
            print src_db_data[splitdbs[1]][1]
            # Construct primary db url
            src_redis_url='redis://admin:'+src_db_data[splitdbs[1]][1]+'@'+src_db_name+'.'+src_db_domain+':443'
            print ">>>>>> SRC URL :", src_redis_url
            create_database(trgt_db_url,trgt_auth_values,trgt_client_cert,trgt_db_userpass,splitdbs[0], db_type, src_redis_url,src_primary_cert)
        else:
            create_database(trgt_db_url,trgt_auth_values,trgt_client_cert,trgt_db_userpass,db, db_type)

if __name__=="__main__":
    main(sys.argv[1:])
