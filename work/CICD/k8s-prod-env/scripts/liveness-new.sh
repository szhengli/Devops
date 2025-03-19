#!/usr/bin/bash

function dingding(){
    date=`date +%F\ %T`
    message="${ENV}-$(hostname) has been restarted ${date}"
    TOKEN="https://oapi.dingtalk.com/robot/send?access_token=70a50eae7eb732c8483e10a514f058717b9eb9fd10f697fc690f12e9d43d431a"
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
    rs=$(curl http://localhost:40000/live 2> /dev/null)
    if ! echo $rs | grep "true" -q
    then
      count=${count}+1
    fi
    sleep 1s
  done
  echo $count
}

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
