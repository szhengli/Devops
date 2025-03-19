#!/bin/bash
set -x
svnRecordUrl="http://zlnet.cnzhonglunnet.com:5801/branch.php/branch/branchmanage"
branch=$1
sysname=$2
data="branchname=${branch}&sysname=${sysname}&type=publish&sign=zlnetwork&username=Jenkins"
curl -d $data ${svnRecordUrl}
