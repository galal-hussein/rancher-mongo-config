#!/bin/bash
echo "Running the Connecting script"
cat << EOF > mongo_replica.py
#!/usr/bin/python
import subprocess
import pymongo
import os
import socket
from pymongo import MongoClient
import time
import netifaces
import dns.resolver
import sys

def mongo_connect(service_name,myip):
    arecords = dns.resolver.query(service_name,'A')
    if len(arecords) <= 3:
	print "The number of Mongo servers is less than 3..can't connect"
	sys.exit(0)
    # also it is assumed that we use 27017 port for now
    #choose random mongo server
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

def get_myip():
    #get ip of the running container
    ipaddress = netifaces.ifaddresses('eth0')[netifaces.AF_INET][1]['addr']
    return ipaddress

if __name__ == "__main__":
    service_name = os.environ['MONGO_SERVICE_NAME']
    myip = get_myip()
    mongo_connect(service_name,myip)
    
EOF
chmod u+x mongo_replica.py
./mongo_replica.py

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
