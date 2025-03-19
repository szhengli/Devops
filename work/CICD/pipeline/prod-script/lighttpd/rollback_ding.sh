#!/bin/bash

set -x
msg=$1

webhook="https://oapi.dingtalk.com/robot/send?access_token=b6425c2040004b17c9df756158a2d25b695e278906f522b7f2ba4c3c3e0f7f2d"



curl $webhook -H 'Content-Type: application/json' -d "
  {
    'msgtype': 'text',
    'text': {
      'content': '${msg} '
    },
    'at': {
      'isAtAll': false
    }
  }"



