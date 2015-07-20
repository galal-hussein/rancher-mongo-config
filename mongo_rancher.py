import subprocess
import pymongo
import requests
import json
import os
import socket
from pymongo import MongoClient
import time
#service name is the name of the service link in rancher
#it is used as an argument to fetch the containers from Rancher's API
#and to add it to the replica set
#
#for ex: service name: mongo
#service id will be the id of the mongo service in Rancher
#and the desired server to add to the replica set is mongo server
def mongo_check(rancher_server, service_name):
    client = MongoClient('mongodb://'+service_name)
    db = client.db
    ismaster= db.command('isMaster')
    if ismaster['ismaster'] == True:
        print "The server is in a replica set and is primary"
    elif ismaster['secondary'] == True:
        print "The server is in a replica set and is secondary"
    else:
        mongo_connect(rancher_server,service_name)

def mongo_connect(ranchersrv,service_name):
    project_url = 'http://'+ranchersrv+'/v1/projects/1a5/services'
    project_resp = requests.get(url=project_url)
    project_data = json.loads(project_resp.text)['data']
    for i in range(len(project_data)):
        if project_data[i]['name'] == service_name:
            service_id = project_data[i]['id']
            break
    url = 'http://'+ranchersrv+'/v1/projects/1a5/services/'+service_id+'/instances'
    service_resp = requests.get(url=url)
    service_data = json.loads(service_resp.text)['data']
    # also it is assumed that we use 27017 port for now
    mongo_address = service_data[0]['primaryIpAddress']+":27017"
    client = MongoClient('mongodb://'+mongo_address)
    db = client.db
    ismaster= db.command('isMaster')
    mongo_primary = ismaster['primary'].split(':')[0]
    port=ismaster['primary'].split(':')[1]
    target_ip = socket.gethostbyname(service_name)
    task="rs.add('"+target_ip+":27017')"
    print task
    subprocess.call(["/usr/bin/mongo", "--host", str(mongo_primary),"--port", str(port), "--eval", task])

def checking_mongo(rancher_server, service_name):
    while True:
        time.sleep(10)
        mongo_check(rancher_server, service_name)

if __name__ == "__main__":
    rancher_server = os.environ['RANCHER_SERVER']
    service_name = os.environ['MONGO_SERVICE_NAME']
    checking_mongo(rancher_server, service_name)
