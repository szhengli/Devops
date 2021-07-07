#!/bin/bash
CHECK="invoke com.zl.framework.dubbo.DubboCommonService.getServiceStatus()"

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
        exit 1
    fi
else
    echo "bad"
    dump
    exit 2
fi


