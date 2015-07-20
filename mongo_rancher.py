import pymongo
from pymongo import MongoClient

def mongo_check(rancher_server, service_name):
    client = MongoClient('mongodb://'+service_name)
    db = client.db
    ismaster= db.command('isMaster')
    if 'secondary' in ismaster and ismaster['ismaster'] == True:
        print "The server is in a replica set and is primary"
    elif 'secondary' in ismaster and ismaster['ismaster'] == False:
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
    mongo_address = service_data[0]['primaryIpAddress']+":27017"
    client = MongoClient('mongodb://'+mongo_address)
    db = client.db
    ismaster= db.command('isMaster')
    client_primary = MongoClient('mongodb://'+ismaster['primary'])





