#!/bin/bash
set -x
svn_path=$SVN_URL_2
[[ $svn_path =~ .*/$  ]] && svn_path=${svn_path:0:$((${#svn_path}-1))}
branch=$(echo $svn_path|awk -F/ '{print  $(NF-1)}')
sysname=$(echo $svn_path|awk -F/ '{print  $NF}')
data="branchname=${branch}&sysname=${sysname}&type=publish&sign=zlnetwork&username=Jenkins"
curl -d $data ${svnRecordUrl}
