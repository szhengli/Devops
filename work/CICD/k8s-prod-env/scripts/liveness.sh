#!/usr/bin/bash
CHECK="invoke com.zl.framework.dubbo.DubboCommonService.getServiceStatus()"

function dingding(){
    date=`date +%F\ %T`
    message="${ENV}-$(hostname) has been restarted ${date}"
    if [[ ${ENV} == prod ]];then
        TOKEN="https://oapi.dingtalk.com/robot/send?access_token=70a50eae7eb732c8483e10a514f058717b9eb9fd10f697fc690f12e9d43d431a"
    else
        TOKEN="https://oapi.dingtalk.com/robot/send?access_token=203b2188a73cb5ac0a5aa9aefb25db26940b0c0fe8284e8d2fa38b3591ce14c3"
    fi
    send="curl $TOKEN -H 'Content-Type: application/json' -d '{\"msgtype\": \"text\", \"text\": { \"content\": \"$message\" }}'"
    eval $send
}

function dump(){
  fileName=$(hostname)_heapdump_$(date +%Y%m%d%H%M).dump
  [ -e /dump ] || mkdir /dump
  timeout 3 jmap -dump:format=b,file=/dump/${fileName} 1
}

function check(){
  declare -i count=0
  for i in $(seq 1 3);do
    rs=$((sleep 0.1;echo ${CHECK};sleep 1;exit)|telnet localhost ${port} 2> /dev/null)
    if ! echo $rs | grep "errorCode" -q
    then
      count=${count}+1
    fi
    sleep 0.1s
  done
  echo $count
}

if port=$(netstat -tnlp | awk -F'[ :/]+' '/1\/java/ {print $4}'|head -1); then
    if [[ ${port} == "0.0.0.0" ]]; then
        port=$(netstat -tnlp | awk -F'[ :/]+' '/1\/java/ {if ($5<6000 && $5>=5000) print $5}')
    fi
    count=$(check)
    if [[ ${count} -gt 2 ]]; then
       echo "bad"
       dump
       dingding
       exit 1
    else
       echo "good"
       exit 0
    fi
else
    echo "bad"
    dump
    dingding
    exit 2
fi
