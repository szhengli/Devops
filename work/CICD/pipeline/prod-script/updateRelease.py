#!/bin/python3
from subprocess import getstatusoutput
from redis.sentinel import Sentinel
import sys,time

service = sys.argv[1]
branch = sys.argv[2]

def update_release(branch="", service="", fieldName="", fieldValue=""):
    keyName = f"{branch}:{service}"
    sentinel = Sentinel([('192.168.1.32', 17020), ('192.168.1.33', 17020),
                         ('192.168.1.34', 17020)], socket_timeout=1)
    try:
        redis = sentinel.master_for('release_master_1', decode_responses=True)
        redis.hmset(keyName, mapping={fieldName: fieldValue,
                                    "service": service
                                    })
    except Exception as e:
        print(e)
        time.sleep(5)
        redis = sentinel.master_for('release_master_1', decode_responses=True)
        redis.hmset(keyName, mapping={fieldName: fieldValue,
                                    "service": service
                                    })
    print("**************************************************")
    print(redis.hgetall(keyName))
    print("**************************************************")

update_release(branch=branch, service=service, fieldName="released", fieldValue="yes")
