from django.shortcuts import render
from django.http import HttpResponse
from subprocess import getstatusoutput
from django.views.decorators.csrf import csrf_exempt
import requests
import re,logging
logger = logging.getLogger("django")

notExistBranch = "svn分支格式有误。正确为年月日,比如:20200831, 请重新填写，谢谢！"

##项目分支专用群dingding机器人URL
dingding = "https://oapi.dingtalk.com/robot/send?access_token=31c90bb3bf6a6f28578fecad607bdfb0080f7df2aa6a09e15f1ecfa0ea18a3ec"

def notify(msg):
    #url = 'https://oapi.dingtalk.com/robot/send?access_token=b69e39a14e141f471829ca4ad8543f38464ab2fec4f617f66d84c19c2a44ea6a'

    data = {"msgtype": "text","text": {"content": msg}}
    status = requests.post(dingding, json=data)
   # status = requests.post(url, json=data)
    print(status.text)


# Create your views here.
@csrf_exempt
def branchRo(request):
    if request.method == 'POST':
        svnAddresses = request.POST.get('svnAddresses')
        svnurls = re.split('[ \n,、，]+', svnAddresses.strip())
        report = ""
        for svnurl in svnurls:
            cmd = 'bash /data/script/branchRo.sh ' + svnurl
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
        return HttpResponse(report)
    else:
        return HttpResponse("This method only support POST")
@csrf_exempt
def branchRw(request):
    if request.method == 'POST':
        svnAddresses = request.POST.get('svnAddresses')
        svnurls = re.split('[ \n,、，]+', svnAddresses.strip())
        report = ""
        for svnurl in svnurls:
            cmd = 'bash /data/script/branchRw.sh ' + svnurl
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
            comment = request.POST.get("comment").replace(' ',  '')
            projects = re.split('[ \n,、，]+', includedSystems.strip())
            for project in projects:
                cmd = "bash /data/script/branchNew.sh %s %s %s %s %s %s" % (year,month,date,project,checkClass(project),comment)
                print(cmd)
                logger.info("分支新建: " + cmd)
                status, msg = getstatusoutput(cmd)
                if status == 0:
                    msg = msg
                else:
                    msg = branch + project + " svn分支创建失败"
                logger.info(msg)
                notify(msg)
            return HttpResponse("completed")
        else:
            notify(notExistBranch)
            logger.info(notExistBranch)
            return HttpResponse("fail to complete")
    else:
        return HttpResponse("This method only support POST")

@csrf_exempt
def branchChange(request):
    if request.method == 'POST':
        branch = request.POST.get('branch')
        if branchIsGood(branch):
            comment = request.POST.get('comment').replace(' ',  '')
            year = branch[0:4]; month = branch[4:6]; date = branch[6:8]
            addedSystems = request.POST.get('addedSystems')
            if addedSystems and addedSystems != "null":
                addedProjects = re.split('[ \n,、，]+', addedSystems.strip())
                for project in addedProjects:
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
            deletedSystems = request.POST.get('deletedSystems')
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
                    else:
                        msg = "svn分支: " + branch + "/" + project + "删除失败!"
                    logger.info(msg)
                    notify(msg)
            return HttpResponse(msg)
        else:
            notify(notExistBranch)
            logger.info(notExistBranch)
            return HttpResponse("fail to complete")
    else:
        return HttpResponse("This method only support POST")

@csrf_exempt
def branchMove(request):
    if request.method == 'POST':
        srcBranch = request.POST.get('srcBranch')
        desBranch = request.POST.get('desBranch')
        if branchIsGood(srcBranch) and branchIsGood(desBranch):
            includedSystems = request.POST.get('includedSystems')
            # 删除说明中的空格，否则shell执行会报错。
            comment = request.POST.get("comment").replace(' ',  '')
            projects = re.split('[ \n,、，]+', includedSystems.strip())
            report = ""
            for project in projects:
                cmd = "bash /data/script/branchMove.sh %s %s %s %s %s" % (srcBranch, desBranch,project,checkClass(project), comment)
                print(cmd)
                logger.info("分支新建: " + cmd)
                status, msg = getstatusoutput(cmd)
                if status == 0:
                    msg = msg
                else:
                    msg = srcBranch + project + " svn分支迁移失败"
                    report = report + msg + "\n"
                logger.info(msg)
                notify(msg)
            return HttpResponse(msg)
        else:
            notify(notExistBranch)
            logger.info(notExistBranch)
            return HttpResponse("fail to complete")
    else:
        return HttpResponse("This method only support POST")


@csrf_exempt
def branchCreate(request):
    if request.method == 'POST':
        releaseDate = request.POST.get('releaseDate')
        year, month, date = releaseDate.split("-")
        includedSystems = request.POST.get('includedSystems')
        projects = re.split('[ \n,、，]+', includedSystems.strip())
        report = ""
        for project in projects:
            cmd = "bash   /data/script/branchCreate.sh %s %s %s %s %s" % (year,month,date,project,checkClass(project))
            print(cmd)
            logger.info("分支新建: " + cmd)
            status, msg = getstatusoutput(cmd)
            if status == 0:
                msg = msg
            else:
                msg = releaseDate + project + " svn分支创建失败"
                report = report + msg + "\n"
            logger.info(msg)
            notify(msg)

        return HttpResponse(report)
    else:
        return HttpResponse("This method only support POST")



@csrf_exempt
def branchAdjust(request):
    if request.method == 'POST':
        report = ""
        comment = request.POST.get('comment').replace(' ',  '')
        branch= request.POST.get('branch')
        year = branch[0:4]; month = branch[4:6]; date = branch[6:8]
        addedSystems = request.POST.get('addedSystems')
        if addedSystems and addedSystems != "null":
            addedProjects = re.split('[ \n,、，]+', addedSystems.strip())
            for project in addedProjects:
                cmd = "bash /data/script/branchCreate.sh %s %s %s %s %s" % (
                       year, month, date, project, checkClass(project))
                print(cmd)
                logger.info("分支调整: " + cmd)
                status, msg = getstatusoutput(cmd)
                if status == 0:
                    msg = msg
                else:
                    msg = branch + project + "分支创建失败"
                    report = report + msg + "\n"
                logger.info(msg)
                notify(msg)
        deletedSystems = request.POST.get('deletedSystems')
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
                else:
                    msg = "svn分支: " + branch + "/" + project + "删除失败!"
                logger.info(msg)
                notify(msg)
        return HttpResponse(msg)
    else:
        return HttpResponse("This method only support POST")


def check(request,branch):
    cmd = 'bash  /data/script/sffb.sh ' + branch
    print("查看分支封板情况: "+ cmd)
    logger.info("查看分支封板情况: "+ cmd)
    status, msg = getstatusoutput(cmd)
    if status != 0:
        msg = "svn分支:  查看分支封板情况 封版失败"
        logger.info(msg)
    return HttpResponse(msg)





