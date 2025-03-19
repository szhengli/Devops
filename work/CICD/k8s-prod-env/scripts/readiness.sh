#!/usr/bin/bash
CHECK="invoke com.zl.framework.dubbo.DubboCommonService.getServiceStatus()"
if port=$(netstat -tnlp | awk -F'[ :/]+' '/1\/java/ {print $4}'|head -1); then
    if [[ ${port} == "0.0.0.0" ]]; then
	port=$(netstat -tnlp | awk -F'[ :/]+' '/1\/java/ {if ($5<6000 && $5>=5000) print $5}')
    fi
    rs=$((echo ${CHECK};sleep 2;exit)|telnet localhost ${port} 2> /dev/null)
    if echo $rs | grep "errorCode" -q ; then
       echo "it is ready"
       exit 0
    else
        echo "starting ...."
        exit 1
    fi
else 
    echo "crushed...."
    exit 2
fi


