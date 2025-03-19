#!/usr/bin/bash
set -x



function getBranchTag (){
   nsContext=" -n ${ENV} --context ${CONTEXT} "
   service=$(kubectl get deployment ${nsContext} | grep ^${serviceName}  -m1 | awk '{print $1}')
   cmdRollout=" kubectl ${nsContext} rollout  history deployment/${service} "
   revisions=$( ${cmdRollout} | grep -v apps | grep -v REVISION |awk   '{print $1}' | sort -nr)
   currentBranch=$(kubectl get  deployment/${service}  ${nsContext}  -o jsonpath="{.metadata.labels['version']}")

   for r in ${revisions}
   do
      branch=$( ${cmdRollout}   --revision $r | awk -F'=' '/version/ { print $2}' )

      if !  [ $currentBranch = $branch ]
      then
          tag=$( ${cmdRollout}  --revision $r | awk -F':' '/Image/ {print $3}')
          echo $branch  $tag
          break
       fi
   done
}


branchAndTag=$(getBranchTag)

branch=$(echo ${branchAndTag} | awk '{print $1}')
ROLLBACK_VERSION=$(echo ${branchAndTag} | awk '{print $2}')



function deploy_to_k8s(){
    if [[ $# -eq 2 ]] ; then
      service=${serviceName}-$1
      replics=$2
    else  
       service=${serviceName}
       replics=$1
    fi
    namespace=${ENV}
    resource=$(eval echo '$'${ENV}_"$(echo ${service}|tr -s "-" "_")_conf")
    image=${REGISTRY}/zhonglun/${service}:${ROLLBACK_VERSION}    

    if [[ -n $resource ]];then
        cpu=$(echo ${resource}|awk '{print $1}') 
        memory=$(echo ${resource}|awk '{print $2}')
        options="--set  imagename=${image},replics=${replics},name=${service},cpu=${cpu},memory=${memory},namespace=${namespace},version=${branch}"
    else
        options="--set  imagename=${image},replics=${replics},name=${service},namespace=${namespace},version=${branch}"
    fi
    helm repo update
    helm upgrade -i ${service}  zhonglun/dubbo-service   ${options} --kube-context ${CONTEXT} -n ${namespace}
    kubectl --context ${CONTEXT} get deploy ${service}  -o wide  -n ${namespace}
}

 case ${serviceName} in
        "zkms"|"dwms"|"zkmsv5"|"dwmsv5")
          deploy_to_k8s $1
        ;;
        "fp"|"basic"|"entry"|"api"|"fms"|"jxms"|"chms"|"ums"|"mcms"|"fpv5"|"basicv5"|"entryv5"|"fpapiv5"|"fmsv5"|"umsv5"|"mcmsv5"|"opmsv5"|"apiv5"|"openv5"|"tiomsv5")
          deploy_to_k8s web $1
        ;;
#        "wsms"|"wsmsv5")
 #         deploy_to_k8s admin $1
  #      ;;
        *) 
          deploy_to_k8s web     $1
          deploy_to_k8s admin   $2
        ;;
 esac

declare -i SUM=0;
while [[ $SUM -lt 20 ]];do
    sleep 3
    if kubectl --context=${CONTEXT} get pods -n $ENV | grep ${serviceName} | grep ContainerCreating ; then
        sleep 10
    else
        for new_pod in $(kubectl --context=${CONTEXT} get  deployment -n $ENV | grep ${serviceName} | awk '{print $1}');do
              while true;do
                if [[ ${CONTEXT} == prodv5 ]];then
                      printf "\e[43;30m点击链接查看启动日志;(登录账号:k8slogs@1399783668292805.onaliyun.com  登录密码:Password1234) \e[0m\n"
                      printf "\e[4;42m https://cs.console.aliyun.com/?spm=5176.12818093.ProductAndService--ali--widget-home-product-recent.dre5.5adc16d0w6H8Ta#/k8s/cluster/c222bb6f0baa641d6b0e1fc16426c2fb9/v2/workload/deployment/detail/prodv5/${new_pod}/pods?type=deployment&clusterType=ManagedKubernetes&profile=Default&state=running&ns=prodv5&region=cn-shanghai \e[0m\n"
                else
                    printf "\e[43;30m点击链接查看启动日志;(登录账号:k8slogs@1399783668292805.onaliyun.com  登录密码:Password1234) \e[0m\n"
                    printf "\e[4;42m https://cs.console.aliyun.com/?spm=5176.12818093.ProductAndService--ali--widget-home-product-recent.dre0.299416d0VjWNJJ#/k8s/cluster/c136870a4a3924110b6a3e63f82e5bd77/v2/workload/deployment/detail/prod/${new_pod}/pods?type=deployment&clusterType=ManagedKubernetes&profile=Default&state=running&ns=prod&region=cn-shanghai&resourceGroupId=-1 \e[0m\n"
                fi
                      break
              done
        done
        break
    fi
    SUM=${SUM}+1
done
echo "程序回滚中，请等待1分钟..."
