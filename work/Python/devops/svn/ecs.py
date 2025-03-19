from aliyunsdkcore.client import AcsClient
from aliyunsdkcore.acs_exception.exceptions import ClientException
from aliyunsdkcore.acs_exception.exceptions import ServerException
from aliyunsdkecs.request.v20140526.StartInstancesRequest import StartInstancesRequest
from aliyunsdkecs.request.v20140526.StopInstancesRequest import StopInstancesRequest
from time import sleep
from requests import get
from json import dumps
from aliyunsdkecs.request.v20140526.StopInstancesRequest import StopInstancesRequest

accessKey = 'LTAI5tHL18n9XwUjTAVyYn1H'
accessSecret = 'RLfowJudNcr7hXNi8f21MLR1TYRnMm'
candidates = [
    ['i-uf680t6q72oziwndwenx', '172.19.225.236'],
    ['i-uf680t6q72oziwndwenv', '172.19.225.234'],
    ['i-uf680t6q72oziwndwenw', '172.19.225.235'],
    ['i-uf67zsc8zufqivduqrmu', '172.19.225.213'],
    ['i-uf69awokk7kwhum34ik1', '172.19.225.251'],
    ['i-uf69awokk7kwhum34ik2', '172.19.225.252'],
    ['i-uf617bvf24v08ace1eek', '172.19.225.253'],
    ['i-uf617bvf24v08ace1eel', '172.19.225.254']
]


def start_ecs(count):
    i = 0
    workers = candidates[0: count]
    ecsIds = [e[0] for e in workers]
    ips = [e[1] for e in workers]
    request = StartInstancesRequest()
    request.set_InstanceIds(ecsIds)
    request.set_accept_format('json')
    client = AcsClient(accessKey, accessSecret, 'cn-shanghai')
    response = client.do_action_with_exception(request)
    print(response)
    print('please wait....')
    sleep(6)
    while i < 20:
        for ip in ips:
            url = 'http://' + ip + ':8080/zabbix/entry/monitor'
            print(url)
            try:
                res = get(url, timeout=2)
                if res.status_code == 200:
                    ips.pop(ips.index(ip))
                    print(ip + ": has passed check!")
            except Exception as e:
                print(e)
                print(ip + "not ready, will check again!")
        if ips:
            sleep(6)
            i = i + 1
        else:
            print("all is ready" + str((i + 1) * 6))
            print(dumps(workers))
            break
    if ips:
        res = "fail to prepare ecs"
    else:
        res = workers
    return res


def stop_ecs(ecs):
    aliRequest = StopInstancesRequest()
    aliRequest.set_InstanceIds(ecs)
    aliRequest.set_accept_format('json')
    client = AcsClient(accessKey, accessSecret, 'cn-shanghai')
    response = client.do_action_with_exception(aliRequest)
    return response.decode()
