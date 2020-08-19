#!/bin/bash
Java_name=`svn list http://192.168.3.144/svn/zlnet/code/project/trunk/Java | tr -d '/'`
Web=`svn list http://192.168.3.144/svn/zlnet/code/project/trunk/Web | tr -d '/'`
Cloudpos=`svn list http://192.168.3.144/svn/zlnet/code/project/trunk/CloudPos | tr -d '/'`
branch=$1
project=$2

for j in $Java_name
  do
    if [ $project = $j ];then
	class_name=Java
	break
      else
	continue
    fi
done

for w in $Web
  do
    if [ $project = $w ];then
        class_name=Web
        break
      else
        continue
    fi
done

for c in $Cloudpos
  do
    if [ $project = $c ];then
        class_name=CloudPos
        break
      else
        continue
    fi
done

class=$class_name
year=`echo $branch | sed -r 's/([0-9])/\1 /g' | awk '{print $1,$2,$3,$4}' | tr -d ' '`
month=`echo $branch | sed -r 's/([0-9])/\1 /g' | awk '{print $5,$6}' | tr -d ' '`
#源SVN路径
source_path=http://192.168.3.144/svn/zlnet/code/project/trunk/$class/$project
#目的SVN路径
des_path=http://192.168.3.144/svn/zlnet/code/project/branch/$year/$month/$branch/$project

if [[ ! -n `svn list http://192.168.3.144/svn/zlnet/code/project/branch/$year/$month | grep $branch` ]]; then
			#判断2020/07/具体分支是否存在，否则新建,完成后并拉取分支
			svn mkdir --parents -m "create $branch $project" http://192.168.3.144/svn/zlnet/code/project/branch/$year/$month/$branch
			svn copy $source_path $des_path -m "create a private $branch of $project" && \
			echo -e "\n[zlnet:/code/project/branch/2020/$month/$branch/$project]\n@$project=rw" >> /data/svn/authz
		else
			#如果分支目录全部存在，指直接拉取新分支
            svn copy $source_path $des_path -m "create a private $branch of $project" && \
            echo -e "\n[zlnet:/code/project/branch/2020/$month/$branch/$project]\n@$project=rw" >> /data/svn/authz

fi
