#!/bin/bash

# Check for lowest ID
sleep 10
/lowest_idx.sh
if [ "$?" -eq "0" ]; then
    echo "This is the lowest numbered contianer.. Handling the initiation."
    /mongo-replset-init.sh $@
else
cat << EOF > mongo_replica.py
#!/usr/bin/python
import subprocess
import pymongo
import os
import socket
from pymongo import MongoClient
import time
import netifaces
import DNS
import sys

def mongo_connect(service_name,myip):
    arecords = DNS.dnslookup(service_name,'A')
    random_mongo_address = str(arecords[0])+":27017"
    client = MongoClient('mongodb://'+random_mongo_address)
    db = client.db
    ismaster= db.command('isMaster')
    # primary mongo server
    mongo_primary = ismaster['primary'].split(':')[0]
    port=ismaster['primary'].split(':')[1]
    task="rs.add('"+myip+"')"
    try:
	subprocess.call(["/usr/bin/mongo", "--host", str(mongo_primary),"--port", str(port), "--eval", task])
    except ValueError as err:
	print(err.msg)

def get_cluster(service_name):
     arecords = DNS.dnslookup(service_name,'A')
     return arecords

def get_myip():
    #get ip of the running container
    ipaddress = netifaces.ifaddresses('eth0')[netifaces.AF_INET][1]['addr']
    return ipaddress

if __name__ == "__main__":
    service_name = os.environ['MONGO_SERVICE_NAME']
    # get cluster len
    print get_cluster(service_name)
    cluster_len = len(get_cluster(service_name))
    myip = get_myip()
    if cluster_len > 3:
        mongo_connect(service_name,myip)
    
EOF
chmod u+x mongo_replica.py
./mongo_replica.py &

if [ $? -ne 0 ]
then
echo "Error Occurred.."
fi

set -e

if [ "${1:0:1}" = '-' ]; then
	set -- mongod "$@"
fi

if [ "$1" = 'mongod' ]; then
	chown -R mongodb /data/db

	numa='numactl --interleave=all'
	if $numa true &> /dev/null; then
		set -- $numa "$@"
	fi

	exec gosu mongodb "$@"
fi

exec "$@"

fi
