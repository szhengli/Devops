#!/bin/bash
CHECK="invoke com.zl.framework.dubbo.DubboCommonService.getServiceStatus()"
function dingding(){
    date=`date +%F\ %T`
    message="${SV_ENV}-$(hostname) has been restarted ${date}"
    TOKEN="https://oapi.dingtalk.com/robot/send?access_token=7cf74b85461895757c7273e9823139cfb2095e349c50c852742f9440a2468b0b"
    send="curl $TOKEN -H 'Content-Type: application/json' -d '{\"msgtype\": \"text\", \"text\": { \"content\": \"$message\" }}'"
    eval $send
}

function dump(){
  fileName=$(hostname)_heapdump_$(date +%Y%m%d%H%M).dump
  [ -e dump ] || mkdir /data/app-logs/dump
  timeout 40 jmap -dump:format=b,file=/data/app-logs/dump/${fileName} 1
  #DUMP_HOST从环境变量中获取
  #sshpass -p $DUMP_PWD   scp  -o StrictHostKeyChecking=no  ${fileName}  root@${DUMP_HOST}:/data/
}

if port=$(netstat -tnlp | awk -F'[ :/]+' '/\/java/ {print $4}' | head -1); then
    if [[ ${port} == "0.0.0.0" ]]; then
       port=$(netstat -tnlp | awk -F'[ :/]+' '/\/java/ {if ($5<6000 && $5>=5000) print $5}')
    fi
    rs=$((echo ${CHECK};sleep 2;exit)|telnet localhost ${port} 2> /dev/null)
    if echo $rs | grep "errorCode" -q ; then
       echo "good"
       exit 0
    else
        echo "bad"
        dump
#	dingding
        exit 1
    fi
else
    echo "bad"
    dump
#    dingding
    exit 2
fi

