#!/bin/bash
function info_msg()
{
    local fmt=$1
    shift && printf "<center><strong><div style='width:300px;text-align:left'>${fmt}</div></strong></center><br>\n"
}

function warn_msg()
{
    local fmt=$1
      
    shift && printf "<font color='#FF0000'><center><strong><div style='width:300px;text-align:left'>${fmt}</div></strong></center></font><br>\n"

    #shift && printf "\033[1;31m${fmt}\033[0m" "$@"
}

function title_msg()
{
    local fmt=$1

    shift && printf "<font color='#000000' size="12"><strong><center>${fmt}</center> </strong></font> <br>\n"

    #shift && printf "\033[1;31m${fmt}\033[0m" "$@"
}
echo '' > /data/wfengban.txt
echo '' > /data/yfengban.txt

branch=$1
year=$(echo ${branch:0:4})
month=$(echo ${branch:4:2})


file_path=${year}'\/'${month}'\/'${branch}
system=$(grep $file_path /data/svn/authz | awk -F/ '{print  $NF}' | tr -d ']' | grep -v '^[0-9]')
title_msg "$branch封版情况" >> /data/wfengban.txt
for sys in $system;do
	if [[ `grep -A 2  $file_path/$sys] /data/svn/authz | grep "^#"` ]]
	then
		info_msg  "$sys------已封版" >> /data/yfengban.txt
	else 
		warn_msg  "$sys------未封版" >> /data/wfengban.txt
	fi
done

cat /data/yfengban.txt >> /data/wfengban.txt
sum_wfb=`cat /data/wfengban.txt | grep '未封版' | wc -l`
sum_yfb=`cat /data/wfengban.txt | grep '已封版' | wc -l`
sum_project=`echo "${sum_wfb}+${sum_yfb}" | bc`
fb_percent=`echo "scale=2;${sum_yfb}/${sum_project}*100" | bc`
sed -i "3i<font color='#191970' size="6"><center><strong><div style='width:300px;text-align:left'>封板率：${fb_percent}%</div></strong></center></font><br>" /data/wfengban.txt
cat /data/wfengban.txt

