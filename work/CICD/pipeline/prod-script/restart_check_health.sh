#!/usr/bin/bash
set -x
web=$1
admin=$2
totalReplics=$((web+admin))
declare -i count=0;
while [[ $count -lt 60 ]]
do 
    echo "!!!!!!!!!!!!!!!!!!!!!" 
    status=$(kubectl --context ${ENV} get pod -n ${ENV} | grep -w ^${serviceName} 2>/dev/null)
    #status=$(kubectl get pod -n ${ENV} --kubeconfig=/root/.kube/test | grep -w ^${serviceName} 2>/dev/null)
    echo "---------------------------"
     if echo "${status}" | grep -q '0/1' ; then
        sleep 15
    else
        currentReplicas=$(echo "${status}"| grep "1/1     Running" -c)
        if [[  ${totalReplics} -eq "${currentReplicas}"  ]] ; then   
           break
        fi
        sleep 15
    fi
    count=${count}+1
    echo "+++++++++++++++"
done
if [[ $count -lt  60 ]] ; then
    echo "重启服务成功"
else
    echo "重启超时，可能失败"
    exit 1
fi
