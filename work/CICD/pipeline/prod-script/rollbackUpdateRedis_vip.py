#!/bin/python3
from subprocess import getstatusoutput
import redis
import sys

service = "rollback:" + sys.argv[1]

host = "r-uf6gv4t13w2e5gngah.redis.rds.aliyuncs.com"
port = 6379
r = redis.StrictRedis(host=host,port=port,decode_responses=True)


if r.exists(service):
    serviceInfo = r.hgetall(service)
    r.hmset(service, mapping={
        "branch": serviceInfo["rbranch"],
        "imageId": serviceInfo["rimageId"]
    })
else:
    print("Key doesnot exist. Unknown error!")
