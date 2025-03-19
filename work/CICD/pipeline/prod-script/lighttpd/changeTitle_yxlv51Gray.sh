#!/bin/sh

set -x

branch=$1

sed -i 's/<title data-env>/<title data-env="gray">/' /data/ftproot/www-root/zhonglunnet.com/release/yxlv51webgray/${branch}/ui/v51/index.html

