#!/bin/bash
set -x
svn_path=$SVN_URL
[[ $svn_path =~ .*/$  ]] && svn_path=${svn_path:0:$((${#svn_path}-1))}
branch=$(echo $svn_path|awk -F/ '{print  $(NF-1)}')
sysname=$(echo $svn_path|awk -F/ '{print  $NF}')
data="branchname=${branch}&sysname=${sysname}&type=publish&sign=zlnetwork&username=Jenkins"
curl -d $data ${svnRecordUrl}

echo "记录生产环境部署服务分支"
curl -d '{ "branch" : ''"'${branch}'"'', "service": ''"'${sysname}'"''}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/recordBranchInProd


