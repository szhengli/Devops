#! /bin/sh
set -x
dingID=$1
ROOT_DIR=/data/ftproot/www-root/zhonglunnet.com
svnName="yxl_web"

PRE_BRANCH=$(ls -ltr ${ROOT_DIR}/release/yxlweb |awk '{branch=res;res=$NF}END{print branch}')
projectPath=${ROOT_DIR}/yxlweb

cd $projectPath

rm -f ui

ln -s ../release/yxlweb/${PRE_BRANCH}/ui/  ui

msg="yxl_web回滚到上一次部署分支${PRE_BRANCH}"

curl -d '{ "branch": ''"'${PRE_BRANCH}'"'', "service": ''"'${svnName}'"''}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/recordBranchInProd


updateJob --service yxl_web --branch ${PRE_BRANCH}

rollback_ding.sh $msg

#curl -u "jenkins:Zhonglun!ef!"  -d '{ "DingID" : ''"'${dingID}'"'', "Service": ''"'${svnName}'"'',"State": "completed"}'  -H "Content-Type: application/json" -X POST http:/172.19.125.135:8088/rollback/updateProgress
