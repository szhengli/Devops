
webhook='https://oapi.dingtalk.com/robot/send?access_token=61dc7b9457b13f9bbd42dbc178d56ef8815c943e5ba331e5eebffe1da506d86b'
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
      'content': '$NOTICE,分支:$BRANCH,系统:$SERVICES,$MESSAGES'
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

