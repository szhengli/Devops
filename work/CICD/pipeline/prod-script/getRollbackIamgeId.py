#!/bin/python3
from subprocess import getstatusoutput
import redis
import sys

service = "rollback:" + sys.argv[1]

host = "r-uf6l6a2nxyvfeaxmmg.redis.rds.aliyuncs.com"
port = 6379
r = redis.StrictRedis(host=host,port=port,decode_responses=True)

if r.exists(service):
    serviceInfo = r.hgetall(service)
    print(serviceInfo["rbranch"] + ":" + serviceInfo["rimageId"] )
else:
    print("None")
