#!/bin/bash
cat << EOF > mongo_cluster_init.py
#!/usr/bin/python
import pymongo
import os
import socket
from pymongo import MongoClient
import time
import netifaces
import DNS
import sys

def cluster_init(service_name):
    port = 27017
    arecords = get_cluster(service_name)
    # initiate rs
    time.sleep(5)
    c = MongoClient("mongodb://"+str(arecords[0]))
    c.admin.command("replSetInitiate")
    cfg = c.admin.command("replSetGetConfig")
    cfg['config']['members']=[]
    for i in range(len(arecords)):
	new_host = dict()
	new_host['_id'] = i
	new_host['host'] = arecords[i]	
	cfg['config']['members'].append(new_host)
    c.admin.command('replSetReconfig', cfg['config'], force=True)
    for i in range(len(arecords)):
	c = MongoClient("mongodb://"+str(arecords[i]))
	
def get_cluster(service_name):
     arecords = DNS.dnslookup(service_name,'A')
     return arecords

def find_master(service_name):
    arecords = get_cluster(service_name)
    for i in arecords:
	client = MongoClient('mongodb://'+i)
        db = client.db
        ismaster= db.command('isMaster')['ismaster']
	if ismaster:
	    return True
    return False
	        
if __name__ == "__main__":
    time.sleep(10)
    # wait for mongo to start
    service_name = os.environ['MONGO_SERVICE_NAME']
    while len(get_cluster(service_name)) < 3:
	print "mongo instances are less than 3.. waiting!"
    	time.sleep(5)
    ismaster = find_master(service_name)
    if ismaster:
	print 'Master is already initated.. nothing to do!'
    else:
	print 'Initiating the cluster!'
	cluster_init(service_name)
    
EOF

# Run cluster init script
chmod u+x mongo_cluster_init.py
./mongo_cluster_init.py &

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

