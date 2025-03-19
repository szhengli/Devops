#tr!/bin/bash
set -e
svn_path=$1
[[ $svn_path =~ .*/$  ]] && svn_path=${svn_path:0:$((${#svn_path}-1))}

branch=$(echo $svn_path|awk -F/ '{print  $(NF-1)}')
system=$(echo $svn_path|awk -F/ '{print  $NF}')

file_path=${branch}'\/'${system}\]

sed -i "/${file_path}/,/^$/  s/=rw$/=r/"  /data/svn/authz



#file_path=${branch}'\/'${system}
#if svn_auth=$(grep -wA 2 $file_path /data/svn/authz | grep @zl-$system); then
#    sed -i "/$file_path/{n;s/$svn_auth/#&/;}" /data/svn/authz
#else
#   exit 1
#fi
