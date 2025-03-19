#/usr/bin/sh
set -x

domainName=yxldyy

pathRoot="/data/ftproot/www-root/zhonglunnet.com"

cd "${pathRoot}/yxlmall/ui"

rm -f v5
ln -s "${pathRoot}/${domainName}/ui"  v5
	
