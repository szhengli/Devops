#!/bin/bash
set -x
svnRecordUrl="http://zlnet.cnzhonglunnet.com:5801/branch.php/branch/branchmanage"
branchStatusUrl="http://zlnet.cnzhonglunnet.com:5801/ajax.php/Index/getBranchStatusByCondition"


if [ -z "$SVN_URL_2" ]; then
     SVN_URL=${SVN_URL_1}
else
     SVN_URL=${SVN_URL_2}
fi

branch=$(echo $SVN_URL|awk -F/ '{print  $(NF-1)}')
sysname=$(echo $SVN_URL|awk -F/ '{print  $NF}')

function CloseVersion() {
    data="branchname=${branch}&sysname=${sysname}&type=close&sign=zlnetwork&username=Jenkins"
    curl -s -d $data ${svnRecordUrl}
}

function GetBranchStatus() {
    data="sysname=${sysname}&branchname=${branch}"
    statusCode=$(curl -s -d $data ${branchStatusUrl} | python -c 'import sys, json; print(json.load(sys.stdin)["data"]["status_code"])')
    if [ -n "$statusCode" ] && [ "$statusCode" -eq 1 ];then
	gray_SendMsg.sh ${BRANCH} ${serviceName} "系统封版失败，请开发人员检查" "发布失败"
        exit 1
    fi
}

CloseVersion
GetBranchStatus
