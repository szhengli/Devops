#tr!/bin/bash
set -e
svn_path=$1

branch=$(echo $svn_path|awk -F/ '{print  $(NF-1)}')
system=$(echo $svn_path|awk -F/ '{print  $NF}')
file_path=${branch}'\/'${system}
svn_auth=`grep -A 1 $file_path /data/svn/authz | tail -1`
if [ -z $svn_auth ]; then
   exit 1
fi
RW=`echo $svn_auth | tr -d '#'`
sed -i "/$file_path/{n;s/$svn_auth/$RW/;}" /data/svn/authz

