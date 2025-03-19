#!/usr/bin/bash

set -x
web=$1
admin=$2
totalReplics=$((web+admin))
declare -i count=0;
while [[ $count -lt 60 ]]
do 
    echo "!!!!!!!!!!!!!!!!!!!!!" 
    status=$(kubectl --context ${CONTEXT} get pod -n ${ENV} | grep -w ^${serviceName} 2>/dev/null)
    echo "---------------------------"
     if echo "${status}" | grep -q '0/1' ; then

        # to restart the deployment if it fails to pass check within the due time.
        if [[ $count -eq  25 ]] ; then
             toRestart=$(echo "${status}" | grep -v "Evicted" | grep  '0/1' |  awk -F- '{ if (NF == 4 ) {print $1 "-" $2 } else {  print $NF  } }'  | sort | uniq )
             for service in ${toRestart}
             do
                  kubectl rollout restart deployment  ${service} --context ${CONTEXT} -n ${ENV}
             done
        fi



        sleep 15
    else
        currentReplicas=$(echo "${status}"| grep "1/1     Running" -c)
        if [[  ${totalReplics} -le "${currentReplicas}"  ]] ; then   
           break
        fi
        sleep 15
    fi
    count=${count}+1
    echo "+++++++++++++++"
done
if [[ $count -lt  60 ]] ; then
    echo "回滚成功"

    nsContext=" -n ${ENV} --context ${CONTEXT} "
    service=$(kubectl get deployment ${nsContext} | grep ^${serviceName}  -m1 | awk '{print $1}')
    lastBranch=$(kubectl get deployment ${service}  ${nsContext} -o jsonpath="{.metadata.labels['version']}" )


    curl -d '{ "branch" : ''"'${lastBranch}'"'', "service": ''"'${serviceName}'"''}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/recordBranchInProd

    updateJob --service  ${serviceName} --branch ${lastBranch}


    msg="${serviceName}回滚到上一次部署分支${lastBranch}"
    rollback_ding.sh $msg

    /usr/bin/rollbackUpdateRedis.py ${serviceName}
else
    echo "回滚超时，可能失败"
    exit 1
fi
