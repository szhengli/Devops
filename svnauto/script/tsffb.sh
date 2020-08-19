#!/bin/bash
function info_msg()
{
    local fmt=$1
    shift && printf "${fmt}"
}

function warn_msg()
{
    local fmt=$1
      
    shift && printf "${fmt}"

    #shift && printf "\033[1;31m${fmt}\033[0m" "$@"
}

function title_msg()
{
    local fmt=$1

    shift && printf "${fmt}"

    #shift && printf "\033[1;31m${fmt}\033[0m" "$@"
}

branch=$1
year=$(echo ${branch:0:4})
month=$(echo ${branch:4:2})

file_path=${year}'\/'${month}'\/'${branch}
system=$(grep $file_path /data/svn/authz | awk -F/ '{print  $NF}' | tr -d ']' | grep -v '^[0-9]')
title_msg "$branch封版情况\n"
for sys in $system;do
	if [ `grep -A 2  $file_path/$sys /data/svn/authz | grep "^#"` ]
	then
		info_msg  "$sys \t已封版\n"
	else
		warn_msg  "$sys \t未封板\n"
	fi
done

