#!/bin/python3
from subprocess import getstatusoutput
import sys
import redis

service = "rollback:" + sys.argv[1]
branch = sys.argv[2]
imageId = sys.argv[3]

host = "r-uf6gv4t13w2e5gngah.redis.rds.aliyuncs.com"
port = 6379
r = redis.StrictRedis(host=host,port=port,decode_responses=True)
if r.exists(service):
    serviceInfo = r.hgetall(service)
    if branch == serviceInfo['branch']:
        r.hset(service, mapping={"imageId": imageId})
    else:
        r.hmset(service, mapping={
            "rbranch": serviceInfo['branch'],
            "rimageId": serviceInfo['imageId'],
            "branch": branch,
            "imageId": imageId
        })
else:
    r.hmset(service, mapping={
        "rbranch": branch,
        "rimageId": imageId,
        "branch": branch,
        "imageId": imageId
    })
