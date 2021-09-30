#!/bin/bash
CHECK="invoke com.zl.framework.dubbo.DubboCommonService.getServiceStatus()"
if port=$(netstat -tnlp | awk -F'[ :/]+' '/\/java/ {print $4}' | head -1); then
    if [[ ${port} == "0.0.0.0" ]]; then
       port=$(netstat -tnlp | awk -F'[ :/]+' '/\/java/ {if ($5<6000 && $5>=5000) print $5}')
    fi
    rs=`(echo ${CHECK};sleep 2;exit)|telnet localhost ${port} 2> /dev/null`
    if echo $rs | grep "errorCode" -q ; then
       echo "good"
       exit 0
    else
       echo "bad2"
       exit 1
    fi
else
    echo "bad1"
    exit 2
fi
