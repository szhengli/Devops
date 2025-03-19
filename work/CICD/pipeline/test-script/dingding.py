#!/usr/bin/python
# -*- coding:UTF-8 -*-
import json,requests,sys,time,datetime

job = sys.argv[1]
service = sys.argv[2]
env= sys.argv[3]
result = sys.argv[4]
servicedict = {
"apiv5":"18651662691",
"basicv5":"18651662691",
"entryv5":"18651662691",
"fmsv5":"18651662691",
"fpapiv5":"18651662691",
"fpv5":"18651662691",
"jobmsv5":"18651662691",
"mcmsv5":"18651662691",
"openv5":"18651662691",
"smsv5":"18651662691",
"umsv5":"18651662691",
"wsmsv5":"18651662691",
"zkmsv5":"18651662691",
"accms":"15195556681",
"accmsv5":"15195556681",
"cdhsv5":"17312148837",
"dcms":"17612520523",
"dcmsv5":"17612520523",
"mbms":"13462477735",
"mbmsv5":"13462477735",
"oms":"18168072100",
"omsv5":"18168072100",
"pays":"17366192796",
"paysv5":"17366192796",
"salems":"13809027713",
"salemsv5":"13809027713",
"stms":"18654058854",
"stmsv5":"18654058854",
"urms":"17512594582",
"urmsv5":"17512594582",
"posms":"13771750790",
"posmsv5":"13771750790",
"qlms":"13951222171",
"scpms":"15262421678",
"srvms":"15262421678",
"acts":"13771750790",
"actsv5":"13771750790",
"osrms":"15262421678",
"opmsv5":"13771750790",
"dwms":"18513411835",
"dwmsv5":"18513411835",
"ifms":"18549920125",
"jxms":"18549920125",
"mallsv5":"18549920125",
"chms":"18549920125",
"wxms":"19963055552",
"wxmsv5":"19963055552",
"wxdatav5":"19963055552",
"zlscms":"13951222171"
        }
url = "https://oapi.dingtalk.com/robot/send?access_token=cf06e085a09ffed0b45de4996aead529f283ba931867519c9d6d5e41f3e91bcb"
title = job + "发布失败"
nowtime = datetime.datetime.now()
nowtime = str(nowtime.strftime('%Y-%m-%d %H:%M:%S')) 
#print(servicedict[service])
mobile = "@" + servicedict[service]
msg = """### 服务发布失败告警: %s \n
> #### 失败时间: %s \n
> #### 失败原因：%s \n
> #### 发布环境: %s \n
> #### 发布服务：%s \n
> #### Job地址: [JenkinsJob地址](http://192.168.1.121:8080/job/%s) \n
> #### 负责人: %s
"""

def Alert():
    headers = {"Content-Type": "application/json"}
    data = {"msgtype": "markdown",
            "markdown": {
                "title": title,
                "text": msg %(title, nowtime, result, env, service, job, mobile)
            },
            "at": {
                "atMobiles": ["18651662691","15195556681","17312148837","17612520523","13462477735","18168072100","17366192796","13809027713","18654058854","17512594582","13771750790",
"13951222171","15262421678","18513411835","18549920125","19963055552"],
                "isAtAll": False
            }
    }

    r = requests.post(url, data=json.dumps(data), headers=headers, verify=False)
    print(r.text)
Alert()
