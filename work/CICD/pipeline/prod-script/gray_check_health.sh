#!/usr/bin/bash

set -x
web=$1
admin=$2
totalReplics=$((web+admin))
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
             toRestart=$(echo "${status}" | grep -v "Evicted" | grep  '0/1' |  awk -F- '{ if (NF == 4 ) {print $1 "-" $2 } else {  print $NF  } }'  | sort | uniq )
             for service in ${toRestart}
             do
                  kubectl rollout restart deployment  ${service} --context ${CONTEXT} -n ${ENV}
             done
        fi


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
    echo "部署成功"
    if [[ $ENV == "prodv5gray"  ]];then
      sh /usr/bin/gray_updateSvnRecord.sh
      curl -d '{ "branch" : ''"'${BRANCH}'"'', "service": ''"'${serviceName}'"'',"synced": false}'  -H "Content-Type: application/json" -X POST http://172.19.125.135:8088/update

      #/usr/bin/deployUpdateRedis.py ${serviceName} ${BRANCH} ${ENV}_${BUILD_NUMBER}_${SVN_REVISION_2}
      #/usr/bin/updateRelease.py ${serviceName} ${BRANCH}
    fi
else
    echo "部署超时，可能失败"
    exit 1
fi
