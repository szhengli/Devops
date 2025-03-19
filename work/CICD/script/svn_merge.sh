#!/bin/bash
brach_rul=$1
branch=`echo $1 | awk -F '/' '{print $(NF-1)}'`
project=`echo $1 | awk -F '/' '{print $NF}'`
cd /data/trunk/Java/$project
if [[ `svn merge http://192.168.1.125/code/branch/$branch/$project --dry-run` ]];then
    cd /data/trunk/Java/$project && \
    svn up && \
    svn merge http://192.168.1.125/code/branch/$branch/$project --dry-run   #请去除--dry-run参数
    message="$brach_rul合并完成"
    TOKEN="https://oapi.dingtalk.com/robot/send?access_token=59e47cf0ad5972555f59f24b7bfbdbbe26862c076799af933d00eb401d929af3"
    send="curl $TOKEN -H 'Content-Type: application/json' -d '{\"msgtype\": \"text\", \"text\": { \"content\": \"$message\" }}'"
    eval $send
else
    message="$brach_rul合并失败"
    TOKEN="https://oapi.dingtalk.com/robot/send?access_token=59e47cf0ad5972555f59f24b7bfbdbbe26862c076799af933d00eb401d929af3"
    send="curl $TOKEN -H 'Content-Type: application/json' -d '{\"msgtype\": \"text\", \"text\": { \"content\": \"$message\" }}'"
    eval $send
fi
