#tr!/bin/bash
#!/bin/bash

srcBranch=$1
srcYear=${srcBranch:0:4}
srcMonth=${srcBranch:4:2}

desBranch=$2
desYear=${desBranch:0:4}
desMonth=${desBranch:4:2}

project=$3
class=$4
comment=$5

authEntry="\n[zlnet:/code/project/branch/${desYear}/${desMonth}/${desBranch}/${project}]\n@zl-${project}=rw"

if [ $class == "newProject" ]
then
   #新项目，需运维人员人工创建。
   echo   "svn分支迁移失败 ：$project 为新项目，运维人员将尽快人工新建此分支，并另行通知。"
    #程序正常提前退出
   exit 0
fi

parent="http://svn.cnzhonglunnet.com/svn/zlnet/code/project"
srcBranchUrl=${parent}/branch/${srcYear}/${srcMonth}/${srcBranch}
auth=" --username svnadmin --password Zhonglun@2020"
#源SVN路径
if !  svn info  $auth  ${srcBranchUrl} &>/dev/null 
then
   echo   "svn分支迁移失败：${srcBranchUrl} 不存在，无法迁移!"
    #程序正常提前退出
   exit 0
fi

#目的SVN路径
desBranchUrl=${parent}/branch/${desYear}/${desMonth}/${desBranch}
#判断目的分支是否存在
if  svn info  $auth  ${desBranchUrl} &>/dev/null
then
      #分支存在，判断分支下这个项目是否存在
      if svn info $auth ${desBranchUrl}/${project} &>/dev/null
      then
          echo   "svn分支迁移失败: ${desBranchUrl}/${project} 已经存在，如需覆盖当前分支，请联系运维人员人工处理。"
          #程序正常提前退出
          exit 0
      fi
       #如果分支,下要创建的项目，不存在，程序继续执行,拉取新分支
      svn copy $auth  $srcBranchUrl/${project} $desBranchUrl/${project} -m "${comment}" &>/dev/null  && \
      echo -e ${authEntry} >> /data/svn/authz
else
       #新建目的分支
       svn mkdir $auth  --parents  ${desBranchUrl} -m "create branch" &>/dev/null
       svn copy $auth  ${srcBranchUrl}/${project} ${desBranchUrl}/${project} -m "${comment}" &>/dev/null  &&  \
       echo -e ${authEntry} >> /data/svn/authz
fi

#删除原分支
if svn rm  $auth  $srcBranchUrl/${project} -m "${comment}" &>/dev/null 
then
    echo  "svn分支迁移成功: 从 ${srcBranchUrl}/${project} 到 ${desBranchUrl}/${project}。"
else
    echo   "svn分支迁移失败: 从 ${srcBranchUrl}/${project} 到 ${desBranchUrl}/${project}。"
fi
   





