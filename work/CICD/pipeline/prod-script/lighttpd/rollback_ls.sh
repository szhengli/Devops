#! /bin/sh
set -x
#dingID=$1
ROOT_DIR=/data/ftproot/www-root/zhonglunnet.com
svnName="lingshou"

PRE_BRANCH=$(ls -ltr ${ROOT_DIR}/release/lingshou |awk '{branch=res;res=$NF}END{print branch}')
projectPath=${ROOT_DIR}/ls

cd $projectPath



rm -f ui

ln -s ../release/lingshou/${PRE_BRANCH}/ui/ ui

msg="lingshou回滚到上一次部署分支${PRE_BRANCH}"

curl -d '{ "branch": ''"'${PRE_BRANCH}'"'', "service": ''"'${svnName}'"''}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/recordBranchInProd

updateJob --service lingshou --branch ${PRE_BRANCH}

rollback_ding.sh $msg

#curl -u "jenkins:Zhonglun!ef!"  -d '{ "DingID" : ''"'${dingID}'"'', "Service": ''"'${svnName}'"'',"State": "completed"}'  -H "Content-Type: application/json" -X POST http:/172.19.125.135:8088/rollback/updateProgress
