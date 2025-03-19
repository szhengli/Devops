#!/usr/bin/bash

set -x
web=$1
admin=$2
totalReplics=$((web+admin))
service=$(kubectl get deploy -n ${ENV}gray  --context prodv5 | grep ^${serviceName}| tail  -n 1 | awk '{print $1}')
branch=$(kubectl get deploy ${service}  -n ${ENV}gray  --context ${CONTEXT}  -o jsonpath={.metadata.labels.version} )

declare -i count=0;


########################### delete obsoletes pods  ###################
errPods=$(kubectl get pods --context ${CONTEXT}  -n ${ENV} | awk '/(ContainerStatusUnknown)|(Error)|(OOMKilled)/ {print $1}' )
if [ -n  "$errPods" ]
then
 echo "going to delete pods: ${errPods}"
 kubectl delete pods  ${errPods}   --context ${CONTEXT}  -n ${ENV}
 echo "deleted"
fi
########################### clean end  ###################



while [[ $count -lt 60 ]]
do 
    echo "!!!!!!!!!!!!!!!!!!!!!" 
    status=$(kubectl --context ${CONTEXT} get pod -n ${ENV} | grep -w ^${serviceName} 2>/dev/null)
    echo "---------------------------"
     if echo "${status}" | grep -v "Evicted" | grep -q '0/1' ; then
        sleep 15
    else
        currentReplicas=$(echo "${status}"| grep "1/1     Running" -c)
        if [  ${totalReplics} -le "${currentReplicas}"  ] ; then   
           break
        fi
        sleep 15
    fi
    count=${count}+1
    echo "+++++++++++++++"
done
if [[ $count -lt  60 ]] ; then
    echo "部署成功"
    echo "update sync record"
    curl -d '{ "branch" : ''"'${branch}'"'', "service": ''"'${serviceName}'"'',"synced": true}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/update
    if [[ $ENV == "prod" || $ENV == "prodv5" ]];then
      echo "xxx"
      sh /usr/bin/sync_updateSvnRecord.sh ${branch} ${serviceName}
      #/usr/bin/deployUpdateRedis.py ${serviceName} ${BRANCH} ${ENV}_${BUILD_NUMBER}_${SVN_REVISION_2}
      #/usr/bin/updateRelease.py ${serviceName} ${branch}
    fi
else
    echo "部署超时，可能失败"
    exit 1
fi
