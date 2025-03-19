#!/bin/bash
set -x
branch=$1
sysname=$2
data="branchname=${branch}&sysname=${sysname}&type=publish&sign=zlnetwork&username=Jenkins"
curl -d $data ${svnRecordUrl}
