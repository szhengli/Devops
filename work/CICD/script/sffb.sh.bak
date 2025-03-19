#!/bin/bash
function info_msg()
{
    local fmt=$1
    shift && printf "<center><strong><div style='width:300px;text-align:left'>${fmt}</div></strong></center><br>"
}

function warn_msg()
{
    local fmt=$1
      
    shift && printf "<font color='#FF0000'><center><strong><div style='width:300px;text-align:left'>${fmt}</div></strong></center></font><br>"

    #shift && printf "\033[1;31m${fmt}\033[0m" "$@"
}

function title_msg()
{
    local fmt=$1

    shift && printf "<font color='#000000' size="12"><strong><center>${fmt}</center> </strong></font> <br>"

    #shift && printf "\033[1;31m${fmt}\033[0m" "$@"
}

branch=$1
year=$(echo ${branch:0:4})
month=$(echo ${branch:4:2})

file_path=${year}'\/'${month}'\/'${branch}
system=$(grep $file_path /data/svn/authz | awk -F/ '{print  $NF}' | tr -d ']' | grep -v '^[0-9]')
title_msg "$branch封版情况"
for sys in $system;do
	if [[ `grep -A 2  $file_path/$sys /data/svn/authz | grep "^#"` ]]
	then
		info_msg  "$sys------已封版\n"
	else
		warn_msg  "$sys------未封板\n"
	fi
done

