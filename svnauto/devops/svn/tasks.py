from celery import shared_task
from random import randrange
import json
from datetime import datetime, timedelta
from .jenkinsop import autoAuth, unsssignRole
from requests import post

def sendMsg(msg):
    ding = "https://oapi.dingtalk.com/robot/" \
         "send?access_token=e1a9d626724454bbdb0a1e180de3c24a4563a111aa44ea09315971d1275dc4ab"
    headers = {'Content-Type': 'application/json;charset=utf-8'}
    data = {"msgtype": "text",
            "text":
                {"content": msg}
            }
    post(ding, data=json.dumps(data), headers=headers)

# the add is only for test
@shared_task
def add(x, y):
    msg = str(x+y) + " " + "jenkins"
    print(msg)
    sendMsg(msg)
    return msg

@shared_task
def autoCreateJenkinsAuth(sysops, target, branch):
    print("begin to create jenkins auth with:" + str(sysops))
    autoAuth(sysops, target, branch)
    msg = "comleted the autocreate in jenkins"
    print(msg)
    sendMsg(msg)
    return msg


@shared_task
def autoRemoveJenkinsAuth(sysops, target):
    print("begin to remove jenkins auth")
    unsssignRole(sysops, target)
    msg = "comleted the removal of auth in jenkins"
    print(msg)
    print(datetime.now())
  #  print(datetime.utcnow())
    sendMsg(msg)
    return msg
