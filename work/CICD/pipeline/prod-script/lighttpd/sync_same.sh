#/usr/bin/sh
set -x
types=$1
domainName=$2
serviceName=$3
grayDomainName=${domainName}"gray"


if [ $types == "qq" ]; then
    pathRoot="/data/ftproot/www-root/zhonglunnet.com"

elif [ $types == "xx" ]; then
    pathRoot="/data/ftproot_xx/www-root/zhonglunnet.com"
else
     echo    "bad service type not qq nor xx"
     exit 10
fi

[ $# -eq 3 ] || exit 10 


grayServicePath=${pathRoot}/${grayDomainName}

cd $grayServicePath

grayPath=$( ls -l ./ |   awk '/ui/ { print $NF } ')

echo "--------"${grayPath}

branch=$(echo $grayPath |awk -F/ '{ print $4}' )

cp -rp   ${pathRoot}/release/${grayDomainName}/${branch} ${pathRoot}/release/${domainName}/ 

# record for sync to生产环境
curl -d '{ "branch" : ''"'${branch}'"'', "service": ''"'${serviceName}'"'',"synced": true}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/update

echo "记录生产环境部署服务分支"
curl -d '{ "branch" : ''"'${branch}'"'', "service": ''"'${serviceName}'"''}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/recordBranchInProd

# invoke qianqi svn
/usr/bin/sync_updateSvnRecord.sh ${branch}  ${serviceName} 

prodServicePath=${pathRoot}/${domainName}

cd  ${prodServicePath}
 ls 
 rm ui 
  echo "remove ui"
  ln -s   ../release/${domainName}/${branch}/ui/     ui





	
