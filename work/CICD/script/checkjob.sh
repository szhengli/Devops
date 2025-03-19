#!bin/bash

auth="--username svnadmin --password Zhonglun@2020 --no-auth-cache"
class=(project framework)
revNum=$1
echo $revNum
svnUrl="http://svn.cnzhonglunnet.com/svn/zlnet/code"
for type in ${class[*]};do
   if [[ ${type} == "framework" ]];then
        addrbs=`svn log $auth -v -c $revNum $svnUrl/$type/branches|grep "^[[:space:]]\+[M|A|D]"|awk '{print $2}'|cut -d/ -f1-8|uniq`
        addrts=`svn log $auth -v -c $revNum $svnUrl/$type/trunk|grep "^[[:space:]]\+[M|A|D]"|awk '{print $2}'|cut -d/ -f1-5|uniq`
   else
	addrb=`svn log $auth -v -c $revNum $svnUrl/$type/branch|grep "^[[:space:]]\+[M|A|D]"|awk '{print $2}'|cut -d/ -f1-8|uniq`
	addrt=`svn log $auth -v -c $revNum $svnUrl/$type/trunk|grep "^[[:space:]]\+[M|A|D]"|awk '{print $2}'|cut -d/ -f1-6|uniq`
   fi 
done
addrs=(${addrb[*]} ${addrt[*]} ${addrbs[*]} ${addrts[*]})
echo "************$(date +"%Y-%m-%d %H-%M-%S")************" >>/svnlog/checklog.log
for addr in ${addrs[*]};do
   if [ -n "$addr" ];then
      #echo "$addr" >/svnlog/checklog.log
      python3 /data/script/buildjob.py  svn/zlnet$addr
   else
      exit 0
   fi
   echo "http://svn.cnzhonglunnet.com/svn/zlnet$addr" >>/svnlog/checklog.log
done
