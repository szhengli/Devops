import jenkins
import xml.etree.ElementTree as ET
import sys , json

svnPath = sys.argv[1]

print(svnPath)

jk = jenkins.Jenkins('http://192.168.1.121:8080/', username='jenkins', password='Zhonglun@2020')

with open('/data/svnjobs.json', 'r', encoding='utf-8') as svnjobmap :
  jobMap=json.load(svnjobmap)

for url  in jobMap.keys():
  if svnPath in url :
     print(jobMap[url])
     for job in jobMap[url]:
       jk.build_job(job)
      
        

