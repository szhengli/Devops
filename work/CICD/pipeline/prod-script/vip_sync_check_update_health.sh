#!/usr/bin/bash

set -x
web=$1
admin=$2
totalReplics=$((web+admin))
#service=$(kubectl get deploy -n ${ENV}gray  --context gray | grep ^${serviceName}| tail  -n 1 | awk '{print $1}')
#branch=$(kubectl get deploy ${service}  -n ${ENV}gray  --context gray  -o jsonpath={.metadata.labels.version} )


service=$(kubectl get deploy -n prodv5  --context prodv5 | grep ^${serviceName}| tail  -n 1 | awk '{print $1}')

if [ -n  "$service" ];
then
   echo "$service  is in prodv5  !!!!!"
   branch=$(kubectl get deploy ${service}  -n prodv5   --context prodv5  -o jsonpath={.metadata.labels.version} )
else
  echo "no valid image in prod cluster at check stage"
  exit 10
fi


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

        # to restart the deployment if it fails to pass check within the due time. 
        if [[ $count -eq  25 ]] ; then
             toRestart=$(echo "${status}" | grep -v "Evicted" | grep  '0/1' |  awk -F- '{ if (NF == 4 ) {print $1 "-" $2 } else {  print $1  } }'  | sort | uniq )
             for service in ${toRestart}
             do
                  kubectl rollout restart deployment  ${service} --context ${CONTEXT} -n ${ENV}
             done
        fi


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

  #  curl -d '{ "branch" : ''"'${branch}'"'', "service": ''"'${serviceName}'"'',"synced": true}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/vip/update
    echo "记录VIP环境部署服务分支"
  #  curl -d '{ "branch" : ''"'${branch}'"'', "service": ''"'${serviceName}'"''}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/vip/recordBranchInVip

else
    echo "部署超时，可能失败"
    exit 1
fi
