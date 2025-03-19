#/usr/bin/sh
set -x
types=$1
domainName=$2
serviceName=$3
vipDomainName=${domainName}"vip"


if [ $types == "qq" ]; then
    pathRoot="/data/ftproot/www-root/zhonglunnet.com"

elif [ $types == "xx" ]; then
    pathRoot="/data/ftproot_xx/www-root/zhonglunnet.com"
else
     echo    "bad service type not qq nor xx"
     exit 10
fi

[ $# -eq 3 ] || exit 10 


servicePath=${pathRoot}/${domainName}

cd $servicePath

path=$( ls -l ./ |   awk '/ui/ { print $NF } ')

echo "--------"${path}

branch=$(echo $path |awk -F/ '{ print $4}' )

cp -rp   ${pathRoot}/release/${domainName}/${branch} ${pathRoot}/release/${vipDomainName}/ 

# record for sync to VIP环境
curl -d '{ "branch" : ''"'${branch}'"'', "service": ''"'${serviceName}'"'',"synced": true}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/vip/update

echo "记录VIP环境部署服务分支"
curl -d '{ "branch" : ''"'${branch}'"'', "service": ''"'${serviceName}'"''}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/vip/recordBranchInVip

# invoke qianqi svn
# /usr/bin/sync_updateSvnRecord.sh ${branch}  ${serviceName} 

vipServicePath=${pathRoot}/${vipDomainName}

cd  ${vipServicePath}
 ls 
 rm ui 
  echo "remove ui"
  ln -s   ../release/${vipDomainName}/${branch}/ui/     ui





	
