#!/bin/bash
set -x
if [ -z "$SVN_URL_2" ]; then
     SVN_URL=${SVN_URL_1}
else
     SVN_URL=${SVN_URL_2}
fi


branch=$(echo $SVN_URL|awk -F/ '{print  $(NF-1)}')
sysname=$(echo $SVN_URL|awk -F/ '{print  $NF}')

data="branchname=${branch}&sysname=${sysname}&type=publishg&sign=zlnetwork&username=Jenkins"
curl -d $data ${svnRecordUrl}
