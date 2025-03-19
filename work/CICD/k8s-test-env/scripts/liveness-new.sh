#!/bin/bash

function dump(){
  fileName=$(hostname)_heapdump_$(date +%Y%m%d%H%M).dump
  [ -e dump ] || mkdir /data/app-logs/dump
  timeout 40 jmap -dump:format=b,file=/data/app-logs/dump/${fileName} 1
  #DUMP_HOST从环境变量中获取
  #sshpass -p $DUMP_PWD   scp  -o StrictHostKeyChecking=no  ${fileName}  root@${DUMP_HOST}:/data/
 
}

rs=$(curl http://localhost:40000/live 2> /dev/null)
if echo $rs | grep "true" -q ; then
    echo "good"
    exit 0
else
    echo "bad"
    dump
    exit 1
fi
