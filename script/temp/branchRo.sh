#!/bin/bash
function error_msg()
{
    local fmt=$1
    shift && printf "\033[1;32m[INFO] [`date +%Y-%m-%d\ %H:%M:%S`] ${fmt}\033[0m" "$@"
}

svn_path=$1
file_path=`echo $svn_path | sed -n 's@http://192.168.3.144/svn/zlnet@@p' | tr '/' '\.'`
svn_auth=`grep -A 1 $file_path /root/svnbak/authz | tail -1`
sed -i "/$file_path/{n;s/$svn_auth/#&/;}" /data/svn/authz
