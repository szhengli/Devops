import jenkins
import xml.etree.ElementTree as ET
import sys

svnPath = sys.argv[1]

print(svnPath)

jk = jenkins.Jenkins('http://192.168.1.121:8080/', username='zhengli', password='Password1234')
remotePath = "definition/scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote"

jobsAll = [job["name"] for job in jk.get_jobs()] 
jobMap = {}

for job in  jobsAll :
   if not "192.168" in job:
     try:
       svnPathOfJob = ET.fromstring(jk.get_job_config(job)).find(remotePath).text
     except Exception as e:
       print("+++++++++++++++++++++++++++++++++++++++++++++++++++")
       continue
     if svnPathOfJob in jobMap.keys() :
       jobMap[svnPathOfJob].append(job)
     else :
       jobMap[svnPathOfJob] = list() 
       jobMap[svnPathOfJob].append(job)
     print("-----------------------------------------------------")

for url  in jobMap.keys():
  if  svnPath in url :
    print(jobMap[url])
 
        

