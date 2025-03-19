from celery import shared_task
from random import randrange
import json
from datetime import datetime, timedelta
from .jenkinsop import autoAuth, unsssignRole, autoAuthRestart, unsssignRoleRestart, changeBranchAndBuild, updateSyncedJobSvn
from requests import post, get
from .syncprod import invokeSync

packageHost="http://pospkg.cnzhonglunnet.com/adp/stable/windows/publish/create.action"

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
    msg = str(x + y) + " " + "jenkins"
    print(msg)
    sendMsg(msg)
    return msg


@shared_task
def autoCreateJenkinsAuth(sysops, target, branch, eta_remove_auth_str):
    print("begin to create jenkins auth with:" + str(sysops))

    print("-----------------------------********* eta_remove_auth *** task ********--------------------------")
    print(type(eta_remove_auth_str))
    print(eta_remove_auth_str)
    print("------------------------------------------------------------------------")

    autoAuth(sysops, target, branch, eta_remove_auth_str)
    msg = "comleted the autocreate in jenkins"
    print(msg)
    sendMsg(msg)
    return msg


@shared_task
def autoRemoveJenkinsAuth(sysops, target, eta_remove_auth_str):
    print("begin to remove jenkins auth")
    unsssignRole(sysops, target, eta_remove_auth_str)
    msg = "comleted the removal of auth in jenkins"
    print(msg)
    print(datetime.now())
    #  print(datetime.utcnow())
    sendMsg(msg)
    return msg


@shared_task
def autoCreateJenkinsAuthRestart(sysops, target, eta_remove_auth_str):
    print("begin to create jenkins auth with:" + str(sysops))
    print(type(eta_remove_auth_str))
    print(eta_remove_auth_str)
    print("------------------------------------------------------------------------")
    autoAuthRestart(sysops, target)
    msg = "comleted the autocreate in jenkins"
    print(msg)
    sendMsg(msg)
    return msg


@shared_task
def autoRemoveJenkinsAuthRestart(sysops, target, eta_remove_auth_str):
    print("begin to remove jenkins auth")
    unsssignRoleRestart(sysops, target)
    msg = "comleted the removal of auth in jenkins"
    print(msg)
    print(datetime.now())
    print(eta_remove_auth_str)
    sendMsg(msg)
    return msg


@shared_task
def autoDeployStandbyService(service, branch):
    changeBranchAndBuild(service, branch)
    msg = "deploy standby service"
    print(msg)
    print(datetime.now())
    sendMsg(msg)
    return msg


@shared_task
def synGrayToProd(sysops, branch, eta_do_sync):
    print("begin to sync job in django :" + str(sysops))

    print("-----------------------------********* eta_remove_auth *** task ********--------------------------")
    print(type(eta_do_sync))
    print(eta_do_sync)
    print("------------------------------------------------------------------------")
    invokeSync(branch, sysops)

    msg = "complete the sync from gray to prod " + branch + ":" + sysops
    print(msg)
    sendMsg(msg)

    # update the svn path of the prod jenkins job
    print(sysops + "原发布job中分支路径开始调整...")
    updateSyncedJobSvn(sysops, branch)
    return msg


@shared_task
def makePosPackage(id):
    payload = {'id': id}
    get(packageHost, params=payload)
    msg = "sent request to pos package host"
    print(msg)
    print(datetime.now())
    sendMsg(msg)
    return msg
