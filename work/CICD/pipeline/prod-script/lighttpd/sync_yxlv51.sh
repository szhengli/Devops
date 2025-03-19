#/usr/bin/sh
set -x
grayServiceName="yxlv51webgray"

pathRoot="/data/ftproot/www-root/zhonglunnet.com"


grayServicePath=${pathRoot}/${grayServiceName}


echo "--${grayServicePath}----"
grayBranch=$(ls -l  ${grayServicePath} |  awk -F'/'   ' /ui/  {print $4}')

echo "--------"


# record for sync to生产环境
  curl -d '{ "branch" : ''"'${grayBranch}'"'', "service": "yxlv51_web","synced": true}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/update


echo "记录生产环境部署服务分支"
  curl -d '{ "branch" : ''"'${grayBranch}'"'', "service": "yxlv51_web" }'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/recordBranchInProd



# invoke qianqi svn 
 /usr/bin/sync_updateSvnRecord.sh ${grayBranch} yxlv51_web

grayReleasePath=${pathRoot}/release/yxlv51webgray/${grayBranch}

prodReleasePath=${pathRoot}/release/yxlv51web

cp -prf ${grayReleasePath} ${prodReleasePath}/

pwd

ls -l  ${prodReleasePath}/${grayBranch}/ui/v51/index.html

sed -i 's/<title data-env="gray">/<title data-env>/' ${prodReleasePath}/${grayBranch}/ui/v51/index.html 

prodServicePath=${pathRoot}/yxlv51web

cd  ${prodServicePath}
ls

rm -f ui

ln -s   ../release/yxlv51web/${grayBranch}/ui/   ui
	
