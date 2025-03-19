#!/bin/bash

# 项目组
PROJECT_TEAM=$1

# 项目的子域名
SUB_DOMAIN_NAME=$2

# 对应NGINX跳转路由
NGINX_PROXY_NAT_PATH="ui"

# 生产环境前端服务器主机ssh账号
REMOTE_HOST_USERNAME="root"

# 生产环境前端服务器主机
REMOTE_HOST="172.19.233.83"

# 前端服务器脚本路径
ROLLBACK_SCRIPT_FILE="/root/shell/rollback.sh"

# 前端服务器主机名
REMOTE_HOSTNAME="web-lighttpd"

# 当前主机名
HOSTNAME=`hostname`

# 显示错误信息
function showError() 
{
        echo $1
        exit 1
}

# 显示步骤日志信息
function showLog()
{
        echo [`date +"%F %H:%M:%S"`] " " $1
}

# 获取PROJECT项目根路径
function getProjectRootDir()
{
        # 根据项目组确定项目根目录
        if [ $PROJECT_TEAM == "xx" ]; then
                FTP_ROOT_DIR="ftproot_xx"
        else
                FTP_ROOT_DIR="ftproot"
        fi
        PROJECT_ROOT_DIR="/data/${FTP_ROOT_DIR}/www-root/zhonglunnet.com"
}


# 版本回滚
function releaseRollback()
{
        # 获取项目根目录 
        getProjectRootDir
        # 进入根目录
        cd $PROJECT_ROOT_DIR || showError "项目根目录进入失败 :("
        # 进入项目目录
        cd $SUB_DOMAIN_NAME || showError "当前项目目录不存在 :("
        # 获取上一个分支版本
        PRE_BRANCH=$(ls -l $PROJECT_ROOT_DIR/release/${SUB_DOMAIN_NAME}|awk '{branch=res;res=$NF}END{print branch}')
        echo "$PRE_BRANCH"
        # 先判断对应分支版本是否存在
        if [ ! -d  ../release/${SUB_DOMAIN_NAME}/${PRE_BRANCH}/${NGINX_PROXY_NAT_PATH}/ ]; then
                showError "${PRE_BRANCH} 分支版本不存在"
        fi

        # 如果分支存在先删除原来的指向
        if [ -L ${NGINX_PROXY_NAT_PATH} ]; then
               # 当前的版本
                showLog "当前的版本指向"
                ls -lh
                # 删除当前版本ui指向
                rm -f ${NGINX_PROXY_NAT_PATH}
        fi

        # 创建指软链接向
        ln -s ../release/${SUB_DOMAIN_NAME}/${PRE_BRANCH}/${NGINX_PROXY_NAT_PATH}/ ${NGINX_PROXY_NAT_PATH} || showError "生产环境版本 ${PRE_BRANCH} 回滚失败 :("
        chown -R www-data.www-data .
        showLog "版本回滚成功，回滚后版本指向如下"
        ls -lh
}

main()
{
        if [ $REMOTE_HOSTNAME == $HOSTNAME ];then
		releaseRollback
        else
        	ssh $REMOTE_HOST_USERNAME@$REMOTE_HOST "${ROLLBACK_SCRIPT_FILE} ${PROJECT_TEAM} ${SUB_DOMAIN_NAME}"
        fi
}

main
