from django.shortcuts import render
from django.http import HttpResponse
from subprocess import getstatusoutput
from django.views.decorators.csrf import csrf_exempt
import requests
import re, logging
from .tasks import autoCreateJenkinsAuth, autoRemoveJenkinsAuth
from datetime import datetime, timedelta
from random import randrange

logger = logging.getLogger("django")
svnBranchParent = "http://svn.cnzhonglunnet.com/svn/zlnet/code/project/branch"
notExistBranch = "svn分支: %s 格式有误。正确为年月日,比如:20200831, 请重新填写，谢谢！"

##项目分支专用群dingding机器人URL
dingding = "https://oapi.dingtalk.com/robot/send?access_token=31c90bb3bf6a6f28578fecad607bdfb0080f7df2aa6a09e15f1ecfa0ea18a3ec"



range_create = (1, 10, 3)
range_remove = (1, 60, 6)

@csrf_exempt
def jenkinsAutoAuth(request):
    if request.method == 'POST':
        # retrieve the params from post data
        target = request.POST.get('target')
        branch = request.POST.get('branch')
        sysops = re.split('[ \n,、，；;]+', request.POST.get('sysops').strip())
        utcPublishTime = datetime.utcfromtimestamp(
                            datetime.strptime(
                                request.POST.get('publishTime'), "%Y-%m-%d %H:%M").timestamp())

        shutdown = request.POST.get('shutdown')
        dbscript = request.POST.get('dbscript')
        packagePOS = request.POST.get('packagePOS')
        comment = request.POST.get('comment')
        applicant = request.POST.get('applicant')

        eta_remove_auth = utcPublishTime + timedelta(hours=1, seconds=randrange(*range_create))
        args_create = (sysops, target, branch)
        args_remove = (sysops, target)
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
















def notify(msg):
    #url = 'https://oapi.dingtalk.com/robot/send?access_token=b69e39a14e141f471829ca4ad8543f38464ab2fec4f617f66d84c19c2a44ea6a'

    data = {"msgtype": "text","text": {"content": msg}}
    status = requests.post(dingding, json=data)
   # status = requests.post(url, json=data)
    print(status.text)

def checkRecord(svnurl,types, username="",branchdesc="",frombranch=""):
    branchname, sysname = svnurl.split('/')[-2:]
    payload = {'branchname': branchname,
               'sysname': sysname, 'type': types,
               'branchdesc': branchdesc, 'username': username,
               'sign': "zlnetwork", 'frombranch': frombranch,
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
    print("---------------------------------------------------------------")

    print(code, message)
    print("---------------------------------------------------------------")
    return code, "svn"+message


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
        print("封版系统列表： "+ str(svnurls))
        print("###################################################")
        for svnurl in svnurls:
            print("#####################^^^^^^^############################")
            print("封版系统:" + svnurl)
            print("########################^^^^###########################")
            code, message = checkRecord(svnurl, "close", username)
            if code == 200:

                cmd = 'bash  /data/script/branchRo.sh ' + svnurl
                print("封板请求: "+ cmd)
                logger.info("封板请求: "+ cmd)
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
        svnurls = re.split('[ \n,、，]+', svnAddresses.strip())
        report = ""
        for svnurl in svnurls:
            code, message = checkRecord(svnurl, "undo", username)
            if code == 200:
                cmd = 'bash   /data/script/branchRw.sh ' + svnurl
                print(cmd)
                logger.info("解板请求: "+ cmd)
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

def checkClass(project):
    parent = "http://svn.cnzhonglunnet.com/svn/zlnet/code/project/trunk/"
    auth = " --username svnadmin  --password Zhonglun@2020 | tr -d / "
    catalogs = ["Java", "MT", "TWeb", "MWeb", "PCWeb", "Public"]
    for cat in catalogs:
        projects = getstatusoutput("svn list " + parent + cat + auth)[1].split('\n')
        if project in projects :
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
        if branchIsGood(branch):
            year = branch[0:4]
            month = branch[4:6]
            date = branch[6:8]
            includedSystems = request.POST.get('includedSystems')
            username = request.POST.get('originatorUserName')
            comment = "分支操作备注:" + request.POST.get("comment").replace(' ',  '').replace('\n', '').replace(';', '')
            projects = re.split('[ \n,、，]+', includedSystems.strip())
            for project in projects:
                svnurl = svnBranchParent + "/" + year +  "/" + month + "/" + branch + "/" + project
                code, message = checkRecord(svnurl, "add", username, comment)
                print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
                print(code, message)
                print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
                if code == 200:
                    cmd = "bash   /data/script/branchNew.sh %s %s %s %s %s %s" % (year,month,date,project,checkClass(project),comment)
                    print(cmd)
                    logger.info("分支新建: " + cmd)
                    status, msg = getstatusoutput(cmd)
                    if status == 0:
                        msg = msg
                    else:
                        msg = branch + project + " svn分支创建失败"
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
        username = request.POST.get('originatorUserName')
        if branchIsGood(branch):
            comment = "分支操作备注:" + request.POST.get('comment').replace(' ',  '').replace('\n', '').replace(';', '')
            year = branch[0:4]; month = branch[4:6]; date = branch[6:8]
            addedSystems = request.POST.get('addedSystems')
            msg = ""
            print("////////////////////////////////////////////////////////////////////////////////")
            print(addedSystems)
            print("////////////////////////////////////////////////////////////////////////////////")
            if addedSystems and addedSystems != "null":
                addedProjects = re.split('[ \n,、，]+', addedSystems.strip())
                for project in addedProjects:
                    svnurl = svnBranchParent + "/" + year + "/" + month + "/" + branch + "/" + project
                    code, message = checkRecord(svnurl, "add", username, comment)
                    if code == 200:
                        cmd = "bash /data/script/branchNew.sh %s %s %s %s %s %s" % (
                               year, month, date, project, checkClass(project), comment)
                        print(cmd)
                        logger.info("分支调整: " + cmd)
                        status, msg = getstatusoutput(cmd)
                        if status == 0:
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
                deletedProjects = re.split('[ \n,、，]+', deletedSystems.strip())
                for project in deletedProjects:
                    cmd = "bash /data/script/branchDel.sh %s %s %s %s %s" % (
                        year, month, date, project, comment)
                    print(cmd)
                    logger.info("分支删除: " + cmd)
                    status, msg = getstatusoutput(cmd)
                    if status == 0:
                        msg = "svn分支: " + branch + "/" + project + "删除成功!"
                        svnurl = svnBranchParent + "/" + year + "/" + month + "/" + branch + "/" + project
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
            comment = "分支操作备注:" + request.POST.get("comment").replace(' ',  '').replace('\n', '').replace(';', '')
            projects = re.split('[ \n,、，]+', includedSystems.strip())
            report = ""
            for project in projects:
                cmd = "bash  /data/script/branchMove.sh %s %s %s %s %s %s" % (srcBranch, desBranch,project,checkClass(project), comment, keep)
                print(cmd)
                logger.info("分支新建: " + cmd)
                status, msg = getstatusoutput(cmd)
                if status == 0:
                    msg = msg
                    svnurl = svnBranchParent + "/" + year + "/" + month + "/" + desBranch + "/" + project
                    checkRecord(svnurl, "move", username, comment, srcBranch)
                    if keep == "yes":
                        svnurlSrc = svnBranchParent + "/" + yearSrc + "/" + monthSrc + "/" + srcBranch + "/" + project
                        checkRecord(svnurlSrc, "add", username, comment)
                        checkRecord(svnurlSrc, "close", username)
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
    print("查看分支封板情况: "+ cmd)
    logger.info("查看分支封板情况: "+ cmd)
    status, msg = getstatusoutput(cmd)
    if status != 0:
        msg = "svn分支:  查看分支封板情况 封版失败"
        logger.info(msg)
    return HttpResponse(msg)






