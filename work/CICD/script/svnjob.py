import jenkins
import xml.etree.ElementTree as ET
import json



jk = jenkins.Jenkins('http://192.168.1.121:8080/', username='zhengli', password='Password1234')
remotePath = "definition/scm/locations/hudson.scm.SubversionSCM_-ModuleLocation/remote"

jobsAll = [job["name"] for job in jk.get_jobs()] 
jobMap = {}

  
for job in  jobsAll :
   if not "192.168" in job:
     try:
       svnPathOfJob = ET.fromstring(jk.get_job_config(job)).find(remotePath).text
       print("............................")
     except Exception as e:
       continue
     if svnPathOfJob in jobMap.keys() :
       jobMap[svnPathOfJob].append(job)
       print("****************************")
     else :
       jobMap[svnPathOfJob] = list() 
       print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
       jobMap[svnPathOfJob].append(job)


with open('/data/svnjobs.json', 'w', encoding='utf-8') as svnjobmap :
  json.dump(jobMap,svnjobmap)

print("completed!") 


