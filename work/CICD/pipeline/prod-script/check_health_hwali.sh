#!/usr/bin/bash

set -x
CONTEXTHW="--kubeconfig /root/.kube/huawei"
web=$1
admin=$2
totalReplics=$((web+admin))
declare -i count=0;
while [[ $count -lt 60 ]]
do 
    echo "!!!!!!!!!!!!!!!!!!!!!" 
    status=$(kubectl --context ${CONTEXT} get pod -n ${ENV} | grep -w ^${serviceName} 2>/dev/null && kubectl ${CONTEXTHW} get pod -n ${ENV} | grep -w ^${serviceName} 2>/dev/null)
    #status=$(kubectl ${CONTEXTHW} get pod -n ${ENV} | grep -w ^${serviceName} 2>/dev/null)
    echo "---------------------------"
     if echo "${status}" | grep -v "Evicted" | grep -q '0/1' ; then
        sleep 15
    else
        currentReplicas=$(echo "${status}"| grep "1/1     Running" -c)
        if [[  $[totalReplics * 2 ] -eq "${currentReplicas}"  ]] ; then   
           break
        fi
        sleep 15
    fi
    count=${count}+1
    echo "+++++++++++++++"
done
if [[ $count -lt  60 ]] ; then
    echo "部署成功"
    if [[ $ENV == "prod" || $ENV == "prodv5" ]];then
      sh /usr/bin/updateSvnRecord.sh
      /usr/bin/deployUpdateRedis.py ${serviceName} ${BRANCH} ${ENV}_${BUILD_NUMBER}_${SVN_REVISION_2}
      /usr/bin/updateRelease.py ${serviceName} ${BRANCH}
    fi
else
    echo "部署超时，可能失败"
    exit 1
fi
