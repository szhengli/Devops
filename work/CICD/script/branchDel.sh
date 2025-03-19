#!/bin/bash
year=$1
month=$2
date=$3
project=$4
branch=$1$2$3
comment="svn$5"
auth=" --username svnadmin --password Zhonglun@2020 "
parent="http://svn.cnzhonglunnet.com/svn/zlnet/code/project/branch"

url=$parent/${year}/${month}/$branch/$project

svn rm  $auth  $url -m "$comment"

eval sed -i  "'/"$branch"\/"$project"\]/,+2d'" /data/svn/authz
