#!/bin/bash
set -x

types=$1
domainName=$2
svnName=$3
dingID=$4
lastBranch=""

if [ $types == "qq" ]; then
    pathRoot="/data/ftproot/www-root/zhonglunnet.com"
elif [ $types == "xx" ]; then
    pathRoot="/data/ftproot_xx/www-root/zhonglunnet.com"
else
     echo    "bad service type not qq nor xx"
     exit 10
fi


echo $pathRoot

normalPath="${pathRoot}/release/${domainName}"

lastBranch=$(ls -ltr ${normalPath} | tail -n2 | head -n1  | awk '{ print $NF }')

echo  $lastBranch


rollbackPath="../release/${domainName}/${lastBranch}/ui/"
prodServicePath=${pathRoot}/${domainName}

cd  ${prodServicePath} && ls 
rm -f  ui 
echo "remove ui"
ln -s  ${rollbackPath}  ui

msg="${svnName}回滚到上一次部署分支${lastBranch}"

updateJob --service ${svnName}   --branch  ${lastBranch}

curl -d '{ "branch": ''"'${lastBranch}'"'', "service": ''"'${svnName}'"''}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/recordBranchInProd


rollback_ding.sh $msg


# record for rollback 
#curl  -u "jenkins:Zhonglun!ef!"   -d '{ "DingID" : ''"'${dingID}'"'', "Service": ''"'${svnName}'"'',"State": "completed"}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/rollback/updateProgress

