import requests
import json
import sys


DRY_RUN=0

def usage():
    print "Creating sample Redis Enterprise databases for 3scale API platform"
    print "Usage: python update_cluster_cert.py <redis cluster url: https://HOST:Port>  <cluster admin user> <cluster admin password> <key file> <certificate file> <type: proxy|syncer>"


def update_cluster_cert(url, auth_value, key, cert, cert_type):

    if cert_type!="proxy" and cert_type!="syncer":
        print "ERROR: Wrong type of the cluster certificate . Should be proxy or syncer"
        usage()
        exit(1)
    put_data={
    "name": cert_type,
    "key": key,
    "certificate": cert
    }

    if DRY_RUN:
        print url
        print json.dumps(put_data, sort_keys=False, indent=2)
    else:
        try:
            response=requests.put(url, auth=auth_value, json=put_data, verify=False)       
        except Exception as ex:
            print "ERROR:Failed to create database with error" ,ex
            print "ERROR:Response:", response
            exit(1)

def get_cert_string(cert_file):

    try:
        with open(cert_file) as f:
            out = '\n'.join(line.strip() for line in f)
    except FileNotFoundError as ex:
        print "ERROR: Couldn't open file, Exception:",ex 
        exit()
    else:
        return out

def main(argv):

    if len(argv)!=6:
        print "ERROR: Wrong number of arguments, application accepts only five arguments"
        usage()
        exit(1)

    
    db_url=argv[0]+"/v1/cluster/update_cert"
    db_auth_values=(argv[1],argv[2])
    cert_key_file=argv[3]
    cert_cert_file=argv[4]
    cert_type=argv[5]

    update_cluster_cert(db_url,db_auth_values,get_cert_string(cert_key_file),get_cert_string(cert_cert_file),cert_type)

if __name__=="__main__":
    main(sys.argv[1:])