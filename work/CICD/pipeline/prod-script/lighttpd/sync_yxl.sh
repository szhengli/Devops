#/usr/bin/sh
set -x
grayServiceName="yxlwebgray"

pathRoot="/data/ftproot/www-root/zhonglunnet.com"


grayServicePath=${pathRoot}/${grayServiceName}


echo "--${grayServicePath}----"
grayBranch=$(ls -l  ${grayServicePath} |  awk -F'/'   ' /ui/  {print $4}')

echo "--------"


# record for sync to生产环境
curl -d '{ "branch" : ''"'${grayBranch}'"'', "service": "yxl_web","synced": true}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/update


echo "记录生产环境部署服务分支"
curl -d '{ "branch" : ''"'${grayBranch}'"'', "service": "yxl_web" }'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/recordBranchInProd



# invoke qianqi svn 
/usr/bin/sync_updateSvnRecord.sh ${grayBranch} yxl_web

grayReleasePath=${pathRoot}/release/yxlwebgray/${grayBranch}

prodReleasePath=${pathRoot}/release/yxlweb

cp -prf ${grayReleasePath} ${prodReleasePath}/

sed -i 's/<title data-env="gray">/<title data-env>/' ${prodReleasePath}/${grayBranch}/ui/v5/index.html 

prodServicePath=${pathRoot}/yxlweb

cd  ${prodServicePath}
ls

rm -f ui
ln -s   ../release/yxlweb/${grayBranch}/ui/   ui
	
