from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
from subprocess import getstatusoutput
from django.views.decorators.csrf import csrf_exempt
import requests
import re, logging
from .tasks import makePosPackage, autoCreateJenkinsAuth, autoRemoveJenkinsAuth, autoCreateJenkinsAuthRestart, synGrayToProd, autoRemoveJenkinsAuthRestart, autoDeployStandbyService
from .jenkinsop import getExistBranchFromJenkins, restartJenkinsJobforPod, updateJOBSvnPath
from datetime import datetime, timedelta
from random import randrange
from .ecs import start_ecs, stop_ecs
from redis.sentinel import Sentinel
from redis import Redis
import json, time
from .accounts import addJiraUser, addSvnUser
from .svnUser import getUsername


logger = logging.getLogger("django")
svnBranchParent = "http://svn.cnzhonglunnet.com/svn/zlnet/code/project/branch"
notExistBranch = "svn分支: %s 格式有误。正确为年月日,比如:20200831, 请重新填写，谢谢！"

##项目分支专用群dingding机器人URL
dingding = "https://oapi.dingtalk.com/robot/send?access_token=31c90bb3bf6a6f28578fecad607bdfb0080f7df2aa6a09e15f1ecfa0ea18a3ec"

rollbackHost="r-uf6s3j8oimh0g3lvgb.redis.rds.aliyuncs.com"

range_create = (1, 10, 3)
range_remove = (1, 60, 6)

standbyService = ["basicv5","entryv5","paysv5","urmsv5","fpv5"]




@csrf_exempt
def branchAddUser(request):
    if request.method == 'POST':
        branch = request.POST.get('branch')
        if branchIsGood(branch):
            year = branch[0:4]
            month = branch[4:6]
            includedSystems = request.POST.get('includedSystems')
            originatorUserName = request.POST.get('originatorUserName')
            svnUsername = getUsername(originatorUserName)
            if not svnUsername:
                msg = f"{originatorUserName} 在svn中不存在用户名，授权失败"
                notify(msg)
                logger.info(msg)
                return HttpResponse(msg)
            perm = "commit"
            projects = re.split('[ \n,、，；;]+', includedSystems.strip().lower())

            for project in projects:
                svnurl = svnBranchParent + "/" + year + "/" + month + "/" + branch + "/" + project
                cmd = f'bash  /data/script/branchAdduser.sh {svnurl}  {svnUsername}  {perm}'
                logger.info("新增系统分支权限: " + cmd)
                status, msg = getstatusoutput(cmd)

                if status == 0:
                    report = f"svn分支: {svnurl}  {originatorUserName} 授权成功"
                    logger.info(report)
                elif status == 1:
                    report = f"svn分支: {svnurl} 处在封板状态 不支持（提交）授权"
                    logger.error(report)
                elif status == 2:
                    report = f"svn分支: {svnurl} 不存在 无法授权"
                    logger.error(report)
                else:
                    report = f"svn分支: {svnurl}  {originatorUserName} 授权失败"
                    logger.error(report)
                logger.info(msg)

                notify(report)

            return HttpResponse(f"{branch}  {includedSystems} 授权结束。")
        else:
            msg = f"{branch}分支号格式不对，正确示例20240315"
            notify(msg)
            logger.error(msg)
            return HttpResponse(msg)
    else:
        return HttpResponse("This method only support POST")







@csrf_exempt
def jiraAddUser(request):
    if request.method == 'POST':
        fullname = request.POST.get('fullname')
        referUser = request.POST.get('referUser')

        if addJiraUser(fullname, referUser):
            return HttpResponse(f"{fullname} jira user 创建成功！")
        else:
            return HttpResponse(f"{fullname} jira user 创建失败！")


@csrf_exempt
def svnAddUser(request):
    if request.method == 'POST':
        user = request.POST.get('user')

        if addSvnUser(user):
            return HttpResponse(f"{user} svn user 创建成功！")
        else:
            return HttpResponse(f"{user} svn user 创建失败！")






@csrf_exempt
def webUpdateJOBSvnPath(request):
    if request.method == 'POST':
        # retrieve the params from post data
        branch = request.POST.get('branch')
        service = request.POST.get('service')
        updateJOBSvnPath(branch,service)
        return HttpResponse(service +" svn path in jenkins Job changed to" + branch + " !")
    else:
        return HttpResponse("this api only support POST!")

@csrf_exempt
def posPackage(request):
    if request.method == 'POST':
        # retrieve the params from post data
        id = request.POST.get('ID')
        print("~~~~~~ ID ~~~~~~~~~~")
        print(id)
        print("~~~~~~~~~~~~~~~~")
        utcPublishTime = datetime.utcfromtimestamp(
            datetime.strptime(
                request.POST.get('publishTime'), "%Y-%m-%d %H:%M").timestamp())
        print("~~~~~~ publishTime in utc  ~~~~~~~~~~")
        print(utcPublishTime)
        print("~~~~~~~~~~~~~~~~")
        eta_do_sync_str = utcPublishTime.strftime("%Y-%m-%d %H:%M")
        args_sync = (id,)
        makePosPackage.apply_async(args_sync, eta=utcPublishTime)
        return HttpResponse("scheduled the pos package job!")


@csrf_exempt
def jenkinsAutoSyProd(request):
    if request.method == 'POST':
        # retrieve the params from post data
        target = request.POST.get('target')
        branch = request.POST.get('branch')
        dingID = request.POST.get('dingID')
        print("~~~~~~~~~~~~~~~~")
        print(branch)
        print(target)
        print("~~~~~~~~~~~~~~~~")
        sysops = request.POST.get('sysops').strip().lower()

        serviceList = [x.replace(' ', '') for x in re.split('[\n,、，；;]+', sysops.strip().lower())]
        if dingID is not None:
            reccord_release(dingID, branch, serviceList)
        publishTime = request.POST.get('publishTime')
        try:
            utcPublishTime = datetime.utcfromtimestamp(
            datetime.strptime(
                publishTime, "%Y-%m-%d %H:%M").timestamp())
        except ValueError:
            print("there is no publish time in application. ")
            utcPublishTime = datetime.utcnow()

        print("~~~~~~~~~~~~~~~~")

        print(utcPublishTime)
        print("~~~~~~~~~~~~~~~~")
        eta_do_sync_str = utcPublishTime.strftime("%Y-%m-%d %H:%M")
        args_sync = (sysops, branch, eta_do_sync_str)
        synGrayToProd.apply_async(args_sync, eta=utcPublishTime)

        for service in serviceList:
            if service in standbyService:
                trigerStandbyBuild(service, branch)
        
        return HttpResponse("submitted the sync job from gray to prod!")


def reccord_release(dingID, branch, serviceList):
    print("**************************************************")
    r = Redis(host=rollbackHost, port=6379, decode_responses=True)
    r.hset('release:'+dingID, mapping={
        'branch': branch,
        'serviceList': json.dumps(serviceList)
    })
    print("**************************************************")


@csrf_exempt
def jenkinsAutoAuth(request):
    if request.method == 'POST':
        # retrieve the params from post data
        target = request.POST.get('target')
        branch = request.POST.get('branch')
        dingID = request.POST.get('dingID')
        sysops = [x.replace(' ', '') for x in re.split('[\n,、，；;]+', request.POST.get('sysops').strip().lower())]

        serviceList = [x.split("@")[0] for x in sysops]

        if target == "生产环境" and dingID is not None:
            reccord_release(dingID, branch, serviceList)

        for service in serviceList:
            try:
                print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
                print(f"branch: {branch}, service: {service}, fieldName: requested, fieldValue=yes")
                print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
                update_release(branch=branch, service=service, fieldName="requested", fieldValue="yes")
            except Exception:
                print(f"fail to update {service} in redis")
            if service in standbyService and target == "生产环境":
                trigerStandbyBuild(service,branch)

        utcPublishTime = datetime.utcfromtimestamp(
            datetime.strptime(
                request.POST.get('publishTime'), "%Y-%m-%d %H:%M").timestamp())

        shutdown = request.POST.get('shutdown')
        dbscript = request.POST.get('dbscript')
        packagePOS = request.POST.get('packagePOS')
        comment = request.POST.get('comment')
        applicant = request.POST.get('applicant')
        if target == "灰度环境":
            delay = 24
        else:
            delay = 6
        eta_remove_auth = utcPublishTime + timedelta(hours=delay, seconds=randrange(*range_create))
       # eta_remove_auth = utcPublishTime + timedelta(minutes=10, seconds=randrange(*range_create))
        eta_remove_auth_str = eta_remove_auth.strftime("%Y-%m-%d %H:%M:%S")
        print("-----------------------------********* eta_remove_auth_str ***********--------------------------")
        print(type(eta_remove_auth_str))
        print(eta_remove_auth_str)
        print("------------------------------------------------------------------------")
        args_create = (sysops, target, branch, eta_remove_auth_str)
        args_remove = (sysops, target, eta_remove_auth_str)
        autoCreateJenkinsAuth.apply_async(args_create, countdown=randrange(*range_create))
        autoRemoveJenkinsAuth.apply_async(args_remove, eta=eta_remove_auth)
        print(sysops)
        print("---------------")
        print(eta_remove_auth)
        print("---------------")
        return HttpResponse("seconds  and  remove will begin at: "

                            )

        '''
                return HttpResponse("auth create at: " +
                            str(countdown_create) + "seconds  and  remove will begin at: "
                            + eta_remove_auth.strftime("%Y-%m-%d %H:%M")
                            )
        '''

    return HttpResponse("this api only support get method")


# Create your views here.


@csrf_exempt
def start_servers(request):
    if request.method == 'POST':
        try:
            count = int(request.POST["count"])
        except Exception:
            return HttpResponse("wrong parmas")
        print("begin startup ecs")
        res = start_ecs(count)
    if request.method == 'GET':
        res = "the API doesnot support get request, pls make POST request instead."
    return JsonResponse(res, safe=False)


@csrf_exempt
def stop_servers(request):
    if request.method == 'POST':
        ecs = request.POST["ecs"]
        ecs = re.split('[ \n,、，；;]+', ecs.strip())
        res = stop_ecs(ecs)
    if request.method == 'GET':
        res = "the API doesnot support get request, pls make POST request instead."
    return JsonResponse(res, safe=False)


def notify(msg):
    # url = 'https://oapi.dingtalk.com/robot/send?access_token=b69e39a14e141f471829ca4ad8543f38464ab2fec4f617f66d84c19c2a44ea6a'

    data = {"msgtype": "text", "text": {"content": msg}}
    status = requests.post(dingding, json=data)
    # status = requests.post(url, json=data)
    print(status.text)



#disabled this
def checkRecord_not_use(svnurl, types, username="", branchdesc="", frombranch="", usefor="", preview=""):
    print("+++++++++++++++???????????++++++++++++++++++++++++++++++++")
    print(usefor)
    print("+++++++++++++++++++++++++++++++++++++++++++++++")
    branchname, sysname = svnurl.split('/')[-2:]

    code = 200
    message = "skip branch check by qianqi!"
    print("---------------------------------------------------------------")

    print(code, message)
    print("---------------------------------------------------------------")
    return code, "svn" + message


# it is normal checkRecord
def checkRecord(svnurl, types, username="", branchdesc="", frombranch="", usefor="", preview=""):
    print("+++++++++++++++???????????++++++++++++++++++++++++++++++++")
    print(usefor)
    print("+++++++++++++++++++++++++++++++++++++++++++++++")
    branchname, sysname = svnurl.split('/')[-2:]
    payload = {'branchname': branchname,
               'sysname': sysname, 'type': types,
               'branchdesc': branchdesc, 'username': username,
               'sign': "zlnetwork", 'frombranch': frombranch,
               'usefor': usefor, 'preview': preview
               }
    url = "http://zlnet.cnzhonglunnet.com:5801/branch.php/branch/branchmanage"
    print(payload)
    r = requests.get(url, params=payload)
    print("**********************************************************************")
    print(r.text)
    print("**********************************************************************")
    res = r.json()
    code = res.get("code")
    message = res.get("message")
    logger.info(message)
    print("---------------------------------------------------------------")

    print(code, message)
    print("---------------------------------------------------------------")
    return code, "svn" + message


# Create your views here.
@csrf_exempt
def branchRo(request):
    if request.method == 'POST':
        svnAddresses = request.POST.get('svnAddresses')
        print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
        print(request.POST)
        username = request.POST.get('originatorUserName')
        print(username)
        print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
        svnurls = re.split('[ \n,、，；;]+', svnAddresses.strip())
        report = ""
        print("###################################################")
        print("封版系统列表： " + str(svnurls))
        print("###################################################")
        for svnurl in svnurls:
            print("#####################^^^^^^^############################")
            print("封版系统:" + svnurl)
            print("########################^^^^###########################")
            code, message = checkRecord(svnurl, "close", username)
            if code == 200:
                update_block(svnurl, "yes")
                cmd = 'bash  /data/script/branchRo.sh ' + svnurl
                print("封板请求: " + cmd)
                logger.info("封板请求: " + cmd)
                status, msg = getstatusoutput(cmd)
                if status == 0:
                    msg = "svn分支:  " + svnurl + " 封版成功"
                    report = report + msg + "\n"
                else:
                    msg = "svn分支: " + svnurl + "由于" + msg + " 封版失败"
                    report = report + msg + "\n"
                logger.info(msg)
                notify(msg)
            else:
                print(message)
                logger.info(message)
                notify(message)
        return HttpResponse(report)
    else:
        return HttpResponse("This method only support POST")


@csrf_exempt
def branchRw(request):
    if request.method == 'POST':
        svnAddresses = request.POST.get('svnAddresses')
        username = request.POST.get('originatorUserName')
        svnurls = re.split('[ \n,、，；;]+', svnAddresses.strip())
        report = ""
        for svnurl in svnurls:
            code, message = checkRecord(svnurl, "undo", username)
            if code == 200:
                update_block(svnurl, "no")
                cmd = 'bash   /data/script/branchRw.sh ' + svnurl
                print(cmd)
                logger.info("解板请求: " + cmd)
                status, msg = getstatusoutput(cmd)
                if status == 0:
                    msg = "svn分支: " + svnurl + "  解版成功"

                    report = report + msg + "\n"
                else:
                    msg = "svn分支: " + svnurl + "由于: " + msg + " 解版失败"
                    report = report + msg + "\n"
                logger.info(msg)
                notify(msg)
            else:
                print(message)
                logger.info(message)
                notify(message)
        return HttpResponse(report)
    else:
        return HttpResponse("This method only support POST")

@csrf_exempt
def branchRoNew(request):
    if request.method == 'POST':
        branch = request.POST.get('branch')
        if branchIsGood(branch):
            year = branch[0:4]
            month = branch[4:6]
            includedSystems = request.POST.get('includedSystems')
            username = request.POST.get('originatorUserName')
            projects = re.split('[ \n,、，；;]+', includedSystems.strip().lower())
            report = ""
            for project in projects:
                svnurl = svnBranchParent + "/" + year + "/" + month + "/" + branch + "/" + project
                code, message = checkRecord(svnurl, "close", username)
                if code == 200:
                    update_block(svnurl, "yes")
                    cmd = 'bash  /data/script/branchRo.sh ' + svnurl
                    print("封板请求: " + cmd)
                    logger.info("封板请求: " + cmd)
                    status, msg = getstatusoutput(cmd)
                    if status == 0:
                        msg = "svn分支:  " + svnurl + " 封版成功"
                        report = report + msg + "\n"
                    else:
                        msg = "svn分支: " + svnurl + " 由于" + msg + " 封版失败"
                        report = report + msg + "\n"
                    logger.info(msg)
                    notify(msg)
                else:
                    print(message)
                    logger.info(message)
                    notify(message)
            return HttpResponse("completed")
        else:
            notify(notExistBranch % branch)
            logger.info(notExistBranch % branch)
            return HttpResponse("fail to complete")
    else:
        return HttpResponse("This method only support POST")


@csrf_exempt
def branchRwNew(request):
    if request.method == 'POST':
        branch = request.POST.get('branch')
        if branchIsGood(branch):
            year = branch[0:4]
            month = branch[4:6]
            includedSystems = request.POST.get('includedSystems')
            username = request.POST.get('originatorUserName')
            projects = re.split('[ \n,、，；;]+', includedSystems.strip().lower())
            report = ""
            for project in projects:
                svnurl = svnBranchParent + "/" + year + "/" + month + "/" + branch + "/" + project
                code, message = checkRecord(svnurl, "undo", username)
                if code == 200:
                    update_block(svnurl, "no")
                    cmd = 'bash  /data/script/branchRw.sh ' + svnurl
                    print("解版请求: " + cmd)
                    logger.info("解版请求: " + cmd)
                    status, msg = getstatusoutput(cmd)
                    if status == 0:
                        msg = "svn分支:  " + svnurl + " 解版成功"
                        report = report + msg + "\n"
                    else:
                        msg = "svn分支: " + svnurl + " 由于" + msg + " 解版失败"
                        report = report + msg + "\n"
                    logger.info(msg)
                    notify(msg)
                else:
                    print(message)
                    logger.info(message)
                    notify(message)
            return HttpResponse("completed")
        else:
            notify(notExistBranch % branch)
            logger.info(notExistBranch % branch)
            return HttpResponse("fail to complete")
    else:
        return HttpResponse("This method only support POST")

@csrf_exempt
def branchRwUG(request):
    if request.method == 'POST':
        includedSystems = request.POST.get('includedSystems')
        username = request.POST.get('originatorUserName')
        projects = re.split('[ \n,、，；;]+', includedSystems.strip().lower())
        report = ""
        for project in projects:
            branch = getExistBranchFromJenkins(project)
            year = branch[0:4]
            month = branch[4:6]
            svnurl = svnBranchParent + "/" + year + "/" + month + "/" + branch + "/" + project
            code, message = checkRecord(svnurl, "undo", username)
            if code == 200:
                update_block(svnurl, "no")
                cmd = 'bash  /data/script/branchRw.sh ' + svnurl
                print("解版请求: " + cmd)
                logger.info("解版请求: " + cmd)
                status, msg = getstatusoutput(cmd)
                if status == 0:
                    msg = "紧急解版--svn分支:  " + svnurl + " 解版成功"
                    report = report + msg + "\n"
                else:
                    msg = "紧急解版--svn分支: " + svnurl + "由于" + msg + " 解版失败"
                    report = report + msg + "\n"
                logger.info(msg)
                notify(msg)
                target = "生产环境"
                sysops = [x.replace(' ', '') for x in re.split('[\n,、，；;]+', project.strip().lower())]
                if "@" not in project:
                    sysops = [x + "@" + request.POST.get('originatorUserName') for x in sysops]
                updateRedisAndAuth(project,branch,sysops,target)
            else:
                print(message)
                logger.info(message)
                notify(message)
        return HttpResponse("completed")
    else:
        return HttpResponse("This method only support POST")

def updateRedisAndAuth(service,branch,sysops,target):
    try:
        print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
        print(f"branch: {branch}, service: {service}, fieldName: requested, fieldValue=yes")
        print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
        update_release(branch=branch, service=service, fieldName="requested", fieldValue="yes")
    except Exception:
        print(f"fail to update {service} in redis")

    utcPublishTime = datetime.utcfromtimestamp(datetime.strptime(datetime.now().strftime("%Y-%m-%d %H:%M"), "%Y-%m-%d %H:%M").timestamp())
    eta_remove_auth = utcPublishTime + timedelta(hours=6, seconds=randrange(*range_create))
    eta_remove_auth_str = eta_remove_auth.strftime("%Y-%m-%d %H:%M:%S")
    print("-----------------------------********* eta_remove_auth_str ***********--------------------------")
    print(type(eta_remove_auth_str))
    print(eta_remove_auth_str)
    print("------------------------------------------------------------------------")
    args_create = (sysops, target, branch, eta_remove_auth_str)
    args_remove = (sysops, target, eta_remove_auth_str)
    autoCreateJenkinsAuth.apply_async(args_create, countdown=randrange(*range_create))
    autoRemoveJenkinsAuth.apply_async(args_remove, eta=eta_remove_auth)


def trigerStandbyBuild(service,branch):
    dayAfterTorromow = datetime.utcnow() + timedelta(days=3)
    args_build = (service, branch)
    autoDeployStandbyService.apply_async(args_build,eta=dayAfterTorromow)


def checkClass(project):
    parent = "http://svn.cnzhonglunnet.com/svn/zlnet/code/project/trunk/"
    auth = " --username svnadmin  --password Zhonglun@2020 | tr -d / "
    catalogs = ["Java", "JT", "MT", "TWeb", "MWeb", "PCWeb", "Public"]
    for cat in catalogs:
        projects = getstatusoutput("svn list " + parent + cat + auth)[1].split('\n')
        if project in projects:
            return cat
    return "newProject"


def branchIsGood(branch):
    try:
        branch = int(branch)
    except Exception:
        return False
    if 20190000 < branch < 21000000:
        return True
    else:
        return False


@csrf_exempt
def branchNew(request):
    if request.method == 'POST':
        branch = request.POST.get('branch')
        logger.info("///////////////////")
        logger.info(branch)
        logger.info("/////////////////")
        print("cccccccccccccccccccccccccccccccccccccccc")   
        if branchIsGood(branch):
            year = branch[0:4]
            month = branch[4:6]
            date = branch[6:8]
            includedSystems = request.POST.get('includedSystems')
            usefor = request.POST.get('useinfo')
            username = request.POST.get('originatorUserName')
            comment = "分支操作备注:" + request.POST.get("comment").replace(' ', '').replace('\n', '').replace(';', '')
            projects = re.split('[ \n,、，；;]+', includedSystems.strip().lower())
            for project in projects:
                svnurl = svnBranchParent + "/" + year + "/" + month + "/" + branch + "/" + project
                code, message = checkRecord(svnurl, "add", username, comment, usefor=usefor)
                print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
                print(code, message)
                print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
                if code == 200:
                    cmd = "bash   /data/script/branchNew.sh %s %s %s %s %s %s" % (
                        year, month, date, project, checkClass(project), comment)
                    print(cmd)
                    logger.info("分支新建: " + cmd)
                    status, msg = getstatusoutput(cmd)
                    if status == 0:
                        ts = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
                        update_release(branch=branch, service=project, fieldName="created", fieldValue=ts, applicant=username)
                        msg = msg
                    else:
                        msg = branch + project + " svn分支创建失败" + " @" + username
                    logger.info(msg)
                    notify(msg)
                else:
                    print(message)
                    logger.info(message)
                    notify(message)
            return HttpResponse("completed")
        else:
            notify(notExistBranch % branch)
            logger.info(notExistBranch % branch)
            return HttpResponse("fail to complete")
    else:
        return HttpResponse("This method only support POST")


@csrf_exempt
def branchChange(request):
    if request.method == 'POST':
        branch = request.POST.get('branch')
        usefor = request.POST.get('useinfo')
        username = request.POST.get('originatorUserName')
        if branchIsGood(branch):
            comment = "分支操作备注:" + request.POST.get('comment').replace(' ', '').replace('\n', '').replace(';', '')
            year = branch[0:4];
            month = branch[4:6];
            date = branch[6:8]
            addedSystems = request.POST.get('addedSystems')
            msg = ""
            print("////////////////////////////////////////////////////////////////////////////////")
            print(addedSystems)
            print("////////////////////////////////////////////////////////////////////////////////")
            if addedSystems and addedSystems != "null":
                addedProjects = re.split('[ \n,、，；;]+', addedSystems.strip())
                for project in addedProjects:
                    svnurl = svnBranchParent + "/" + year + "/" + month + "/" + branch + "/" + project
                    code, message = checkRecord(svnurl, "add", username, comment, usefor=usefor)
                    if code == 200:
                        cmd = "bash /data/script/branchNew.sh %s %s %s %s %s %s" % (
                            year, month, date, project, checkClass(project), comment)
                        print(cmd)
                        logger.info("分支调整: " + cmd)
                        status, msg = getstatusoutput(cmd)
                        if status == 0:
                            ts = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
                            update_release(branch=branch, service=project, fieldName="created", fieldValue=ts, applicant=username)
                            msg = msg
                        else:
                            msg = branch + project + "分支创建失败"
                        logger.info(msg)
                        notify(msg)
                    else:
                        print(message)
                        logger.info(message)
                        notify(message)
                        msg = message
            deletedSystems = request.POST.get('deletedSystems')
            print("//////////////////////////888888888//////////////////////////////////////////////////////")
            print(deletedSystems)
            print("/////////////////////////////8888888///////////////////////////////////////////////////")
            if deletedSystems and deletedSystems != "null":
                deletedProjects = re.split('[ \n,、，;]+', deletedSystems.strip())
                for project in deletedProjects:
                    cmd = "bash /data/script/branchDel.sh %s %s %s %s %s" % (
                        year, month, date, project, comment)
                    print(cmd)
                    logger.info("分支删除: " + cmd)
                    status, msg = getstatusoutput(cmd)
                    if status == 0:
                        msg = "svn分支: " + branch + "/" + project + "删除成功!"
                        svnurl = svnBranchParent + "/" + year + "/" + month + "/" + branch + "/" + project
                        ts = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
                        update_release(branch=branch, service=project, fieldName="deleted", fieldValue=ts)
                        checkRecord(svnurl, "remove", username, comment)
                    else:
                        msg = "svn分支: " + branch + "/" + project + "删除失败!"
                    logger.info(msg)
                    notify(msg)
            return HttpResponse(msg)
        else:
            notify(notExistBranch % branch)
            logger.info(notExistBranch % branch)
            return HttpResponse("fail to complete")
    else:
        return HttpResponse("This method only support POST")


@csrf_exempt
def branchMove(request):
    if request.method == 'POST':
        srcBranch = request.POST.get('srcBranch')
        desBranch = request.POST.get('desBranch')
        yearSrc = desBranch[:4]
        monthSrc = desBranch[4:6]
        year = desBranch[:4]
        month = desBranch[4:6]
        username = request.POST.get('originatorUserName')
        keep = request.POST.get('keep')
        msg = ""
        if branchIsGood(srcBranch) and branchIsGood(desBranch):
            includedSystems = request.POST.get('includedSystems')
            # 删除说明中的空格，否则shell执行会报错。
            comment = "分支操作备注:" + request.POST.get("comment").replace(' ', '').replace('\n', '').replace(';', '')
            projects = re.split('[ \n,、，；;]+', includedSystems.strip().lower())
            report = ""
            for project in projects:
                svnurl = svnBranchParent + "/" + year + "/" + month + "/" + desBranch + "/" + project
                code, message = checkRecord(svnurl, "move", username, comment, srcBranch, preview=1)
                if code == 200:
                    cmd = "bash  /data/script/branchMove.sh %s %s %s %s %s %s" % (
                        srcBranch, desBranch, project, checkClass(project), comment, keep)
                else:
                    notify(message)
                    continue
                print(cmd)
                logger.info("分支新建: " + cmd)
                status, msg = getstatusoutput(cmd)
                if status == 0:
                    msg = msg
                    svnurl = svnBranchParent + "/" + year + "/" + month + "/" + desBranch + "/" + project
                    checkRecord(svnurl, "move", username, comment, srcBranch)
                    ts = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
                    if keep == "yes":
                        svnurlSrc = svnBranchParent + "/" + yearSrc + "/" + monthSrc + "/" + srcBranch + "/" + project
                        checkRecord(svnurlSrc, "add", username, comment)
                        checkRecord(svnurlSrc, "close", username)
                    else:
                        update_release(branch=srcBranch, service=project, fieldName="deleted", fieldValue=ts, applicant=username)
                    update_release(branch=desBranch, service=project, fieldName="created", fieldValue=ts)
                else:
                    msg = srcBranch + project + " svn分支迁移失败"
                    report = report + msg + "\n"
                logger.info(msg)
                notify(msg)
            return HttpResponse(msg)
        else:
            if branchIsGood(srcBranch):
                notify(notExistBranch % desBranch)
                logger.info(notExistBranch % desBranch)
            else:
                notify(notExistBranch % srcBranch)
                logger.info(notExistBranch % srcBranch)
            return HttpResponse("fail to complete")
    else:
        return HttpResponse("This method only support POST")


def check(request, branch):
    cmd = 'bash  /data/script/sffb.sh ' + branch
    print("查看分支封板情况: " + cmd)
    logger.info("查看分支封板情况: " + cmd)
    status, msg = getstatusoutput(cmd)
    if status != 0:
        msg = "svn分支:  查看分支封板情况 封版失败"
        logger.info(msg)
    return HttpResponse(msg)





def update_release(branch="", service="", fieldName="", fieldValue="", applicant=""):
    keyName = f"{branch}:{service}"
    sentinel = Sentinel([('192.168.1.32', 17020), ('192.168.1.33', 17020),
                         ('192.168.1.34', 17020)], socket_timeout=0.1)
    redis = sentinel.master_for('release_master_1', decode_responses=True)
    if fieldName == "deleted":
        redis.delete(keyName)
        return
    redis.hmset(keyName, mapping={fieldName: fieldValue,
                                  "service": service
                                  })
    if applicant:
        redis.hmset(keyName, mapping={"applicant": applicant})
    print("**************************************************")
    print(redis.hgetall(keyName))
    print("**************************************************")


def update_block(svnurl, block):
    if svnurl.endswith('/'):
        branch, service = svnurl.split('/')[-3:-1]
    else:
        branch, service = svnurl.split('/')[-2:]
    try:
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print(f"branch: {branch}, service: {service}, fieldName: block, fieldValue={block}")
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        update_release(branch=branch, service=service, fieldName="block", fieldValue=block)
    except Exception:
        print(f"fail to update {service} in redis")

@csrf_exempt
def get_all_branches(request):
    sentinel = Sentinel([('192.168.1.32', 17020), ('192.168.1.33', 17020),
                         ('192.168.1.34', 17020)], socket_timeout=0.1)
    redis = sentinel.master_for('release_master_1', decode_responses=True)
    branches = sorted(list(set(list(x.split(":")[0] for x in redis.keys("202*")))), reverse=True)
    data = [{"value": x, "label": x} for x in branches]
    return JsonResponse(data, safe=False)

def get_release(branch="20210831"):
    pattern = f"{branch}:*"
    sentinel = Sentinel([('192.168.1.32', 17020), ('192.168.1.33', 17020),
                         ('192.168.1.34', 17020)], socket_timeout=0.1)
    redis = sentinel.master_for('release_master_1', decode_responses=True)
    return [redis.hgetall(keyName) for keyName in redis.keys(pattern)]

@csrf_exempt
def get_release_records(request):
    if request.method == 'POST':
        data = json.loads(request.body.decode())
        branch = data['branch']
        print(branch)
        return JsonResponse(get_release(branch), safe=False)
    else:
        return HttpResponse("This api only support POST")


@csrf_exempt
def jenkinsAutoAuthRestart(request):
    if request.method == 'POST':
        # retrieve the params from post data
        target = request.POST.get('target')
        sysops = [x.replace(' ', '') for x in re.split('[\n,、，；;]+', request.POST.get('sysops').strip().lower())]
        if "@" not in request.POST.get('sysops'):
            sysops = [x + "@" + request.POST.get('originatorUserName') for x in sysops]
        serviceList = [x.split("@")[0] for x in sysops]
        for service in serviceList:
            print(service)
            restartJenkinsJobforPod(service)
        utcPublishTime = datetime.utcfromtimestamp(
                datetime.strptime(request.POST.get('publishTime'), "%Y-%m-%d %H:%M").timestamp())
        eta_remove_auth = utcPublishTime + timedelta(hours=6, seconds=randrange(*range_create))
        eta_remove_auth_str = eta_remove_auth.strftime("%Y-%m-%d %H:%M:%S")
        args_create = (sysops, target, eta_remove_auth_str)
        args_remove = (sysops, target, eta_remove_auth_str)
        autoCreateJenkinsAuthRestart.apply_async(args_create, countdown=randrange(*range_create))
        autoRemoveJenkinsAuthRestart.apply_async(args_remove, eta=eta_remove_auth)  
        print(sysops)
    return HttpResponse("this api only support get method")
