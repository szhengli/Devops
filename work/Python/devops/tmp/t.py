from jenkins import Jenkins, NotFoundException
from xpinyin import Pinyin
import xml.etree.ElementTree as ET
import re
from redis.sentinel import Sentinel
from datetime import datetime

NORMAL_SVN_ROOT = "http://svn.cnzhonglunnet.com/svn/zlnet/code/project/branch/"
JENKINS_CONN = {"url": "http://192.168.1.121:8080/", "username": "zhengli", "password": "11da7707d2297af146d71d01b56c5e5f8e"}
#JENKINS_CONN = {"url": "http://172.19.125.135:8080/", "username": "admin", "password": "11bbd62e96c8390d2920a2d6bcd24696fb"}


def updateJOBSvnPath(branch, service):
    jk = Jenkins(**JENKINS_CONN)
    year = branch[:4]
    month = branch[4:6]
    svnUrl = NORMAL_SVN_ROOT + year + "/" + month + "/" + branch + "/" + service + "@HEAD"
    jobDesc = "系统: {service}----分支: {branch}".format(service=service, branch=branch)
    if service.endswith(("v5", "v5_h5")):
        jobName = "prodv5-prodv5-" + service
    else:
        jobName = "prod-prod-" + service
    try:
        jobConfig = ET.fromstring(jk.get_job_config(jobName))
    except NotFoundException:
        msg = jobName + " NOT found! "
        print(msg)
        return
    try:
        jobConfig.find("scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote").text = svnUrl
    except AttributeError:
        jobConfig.findall("definition/scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote")[1].text = svnUrl
    jobConfig.find('description').text = jobDesc
    jk.reconfig_job(jobName, ET.tostring(jobConfig).decode())

branch, service = "20241129","yxl_web"
updateJOBSvnPath(branch, service)
