#!/bin/bash
webhook='https://oapi.dingtalk.com/robot/send?access_token=0b59ceb27a3de5f26b7f58c401027699e6a392a573ec82e6d98ac986a09621b9'
#webhook='https://oapi.dingtalk.com/robot/send?access_token=c4e1579cc9fa39b8895c729369c35ea7e1b314ddca889dd2bc1ed055588eef84'
BRANCH=$1
SERVICES=$2
MESSAGES=$3
NOTICE=$4
SVNADDRS=$5
USERNAME="jenkins"

#发布前(SVN)封板
function CoverVersion() {
  curl http://58.210.99.210:8010/svn/branchRo/ -X POST -d "svnAddresses=$SVNADDRS&originatorUserName=$USERNAME" &
}

#发布钉钉消息通知
function SendMsgToDingding() {
  curl $webhook -H 'Content-Type: application/json' -d "
  {
    'msgtype': 'text',
    'text': {
      'content': '$NOTICE！！！\n VIP环境, $BRANCH/$SERVICES $MESSAGES！\n'
    },
    'at': {
      'isAtAll': false
    }
  }"
}

if [[ -n $5 ]];then
    CoverVersion
fi   
SendMsgToDingding
