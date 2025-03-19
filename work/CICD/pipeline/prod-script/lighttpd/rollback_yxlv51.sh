#! /bin/sh
set -x
dingID=$1
ROOT_DIR=/data/ftproot/www-root/zhonglunnet.com
svnName="yxlv51_web"

PRE_BRANCH=$(ls -ltr ${ROOT_DIR}/release/yxlv51web |awk '{branch=res;res=$NF}END{print branch}')
projectPath=${ROOT_DIR}/yxlv51web

cd $projectPath

rm -f ui

ln -s ../release/yxlv51web/${PRE_BRANCH}/ui/  ui

msg="yxlv51_web回滚到上一次部署分支${PRE_BRANCH}"

curl -d '{ "branch": ''"'${PRE_BRANCH}'"'', "service": ''"'${svnName}'"''}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/recordBranchInProd


updateJob --service yxlv51_web --branch ${PRE_BRANCH}

rollback_ding.sh $msg

#curl -u "jenkins:Zhonglun!ef!"  -d '{ "DingID" : ''"'${dingID}'"'', "Service": ''"'${svnName}'"'',"State": "completed"}'  -H "Content-Type: application/json" -X POST http:/172.19.125.135:8088/rollback/updateProgress
