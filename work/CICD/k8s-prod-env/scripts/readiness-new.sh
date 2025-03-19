#!/bin/bash
if [ -f readiness.count ];then
    count=`cat readiness.count`
    if [ $count -lt 50 ]; then
        count=$((count+1))
        echo $count > readiness.count
        needOnline=true
    fi
else
    echo 0 > readiness.count
    needOnline=true
fi


rs=`curl --connect-timeout 2 http://localhost:40000/ready 2> /dev/null`
if echo $rs | grep "true" -q ; then
    echo "it is ready" 
    exit 0
else
    if [[ $needOnline == "true" ]] ; then
        echo "invoke dubbo service online command" >> readiness.log
        curl --connect-timeout 2 http://localhost:40000/online  &>>readiness.log
    fi
    exit 1
fi
