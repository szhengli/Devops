#!/bin/bash
echo "-------------- Begin Startup check at $(date) -------------------------"  >>  startup.log
rs=`curl --connect-timeout 5 http://localhost:40000/startup 2> /dev/null`
if echo $rs | grep "true" -q ; then
    echo  "Pass startup check. "  >> startup.log
    echo "!!!!!!!!!!!!!!!!! Startup check completes  at $(date) !!!!!!!!!!!!!!!!!!"  >>  startup.log
    exit 0
else
    echo "invoke dubbo service online command " >>  startup.log
    curl --connect-timeout 5 http://localhost:40000/online  &>> startup.log
    echo "!!!!!!!!!!!!!!!!! Startup check completes  at $(date) !!!!!!!!!!!!!!!!!!"  >>  startup.log
    exit 1
fi
