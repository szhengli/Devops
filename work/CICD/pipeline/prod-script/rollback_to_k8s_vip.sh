#!/usr/bin/bash
set -x
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
    ROLLBACK_INFO=$(getRollbackIamgeId_vip.py ${serviceName})
    if echo "$ROLLBACK_INFO"|grep "vip" -q;then
       ROLLBACK_BRANCH=$(echo ${ROLLBACK_INFO}|awk -F[:] '{print $1}')
       ROLLBACK_VERSION=$(echo ${ROLLBACK_INFO}|awk -F[:] '{print $2}')
       image=${REGISTRY_VIP}/zhonglun/${service}:${ROLLBACK_VERSION}
       echo "正在回滚到分支:${ROLLBACK_BRANCH} 镜像版本号:${ROLLBACK_VERSION}"
    else
       echo "未找到${service}镜像，回滚失败"
       exit 1
    fi
    if [[ -n $resource ]];then
        cpu=$(echo ${resource}|awk '{print $1}') 
        memory=$(echo ${resource}|awk '{print $2}')
        options="--set  imagename=${image},replics=${replics},name=${service},cpu=${cpu},memory=${memory},namespace=${namespace}"
    else
        options="--set  imagename=${image},replics=${replics},name=${service},namespace=${namespace}"
    fi
    helm repo update
    helm upgrade -i ${service}  vip-service/dubbo-service   ${options} --kube-context ${CONTEXT} -n ${namespace}
    kubectl --context ${CONTEXT} get deploy ${service}  -o wide  -n ${namespace}
}

 case ${serviceName} in
        "zkmsv5"|"dwmsv5")
          deploy_to_k8s $1
        ;;
        "fpv5"|"basicv5"|"entryv5"|"fpapiv5"|"fmsv5"|"umsv5"|"mcmsv5"|"opmsv5"|"apiv5"|"openv5"|"wxdatasv5")
          deploy_to_k8s web $1
        ;;
        #"wsms"|"wsmsv5")
        #  deploy_to_k8s admin $1
        #;;
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
                if [[ ${CONTEXT} == vipv5 ]];then
                      printf "\e[43;30m点击链接查看启动日志;(登录账号:k8slogs@1399783668292805.onaliyun.com  登录密码:Password1234) \e[0m\n"
                      printf "/e[4;42m https://cs.console.aliyun.com/?spm=5176.12818093.ProductAndService--ali--widget-home-product-recent.dre5.5adc16d0w6H8Ta#/k8s/cluster/ca2ea982e55ea4ca18cf4531bf779d4e6/v2/workload/deployment/detail/vipv5/${new_pod}/logs?type=deployment&clusterType=ManagedKubernetes&profile=Default&state=running&ns=vipv5&region=cn-hangzhou&resourceGroupId=rg-aek2ejitwu2675a \e[0m\n"
                fi
                      break
              done
        done
        break
    fi
    SUM=${SUM}+1
done
echo "程序回滚中，请等待1分钟..."
