from subprocess import getstatusoutput
from redis import Redis

dualServices = ["accms", "acts", "dcms", "ifms", "jobms",
                "mbms","oms", "osrms", "pays", "posms", "salems",
                "scpms", "sms", "srvms", "stms", "urms", "wxms",
                "zlscms", "accmsv5", "actsv5", "dcmsv5", "jobmsv5",
                "mbmsv5", "omsv5", "paysv5", "posmsv5", "salemsv5",
                "smsv5", "stmsv5", "urmsv5", "wxmsv5"]

webOnlyServices = ["api", "basic", "chms", "entry", "fms",
                   "fp", "jxms", "mcms", "ums", "apiv5", "basicv5",
                   "chmsv5", "entryv5", "fmsv5", "fpapiv5", "fpv5",
                   "mcmsv5", "opmsv5", "umsv5"]

adminOnlyServices = ["wsms", "wsmsv5"]
singleService = ["zkms", "dwms", "dwmsv5", "zkmsv5"]

javaServices = dualServices + webOnlyServices + webOnlyServices + singleService



def get_image_for_java(service):
    if service in dualServices + webOnlyServices:
        service = service + "-web"
    elif service in adminOnlyServices:
        service = service + "-admin"
    elif service in singleService:
        pass
    else:
        print("something wrong with service")
        exit(10)
    cmd = "kubectl get  deploy " + service + " -o=jsonpath='{.spec.template.spec.containers[0].image}'" \
                                             "  -n prod   --context prod"
    status, image = getstatusoutput(cmd)
    if image:
        serviceKey = "rollback:" + service
        redis = Redis(host='172.19.233.38', port=6379, decode_responses=True)
        redis.set(serviceKey, image)
    else:
        print("wrong image ID")





