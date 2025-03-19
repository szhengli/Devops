#!/usr/bin/bash
set -x
CONTEXTHW="--kubeconfig /root/.kube/huawei"
function deploy_to_k8s(){
    if [[ $# -eq 2 ]] ; then
      service=${serviceName}-$1
      replics=$2
    else  
       service=${serviceName}
       replics=$1
    fi
    #resource=$(eval echo '$'"$(echo ${service}|tr -s "-" "_")_conf")
    resource=$(eval echo '$'${ENV}_"$(echo ${service}|tr -s "-" "_")_conf")
    image=${REGISTRY}/zhonglun/${service}:${ENV}_${BUILD_NUMBER}_${SVN_REVISION_2}
    namespace=${ENV}
    if [[ -n $resource ]];then
        cpu=$(echo ${resource}|awk '{print $1}') 
        memory=$(echo ${resource}|awk '{print $2}')
        options="--set  imagename=${image},replics=${replics},name=${service},cpu=${cpu},memory=${memory},namespace=${namespace}"
    else
        options="--set  imagename=${image},replics=${replics},name=${service},namespace=${namespace}"
    fi
    helm repo update
    #if helm list  --kube-context ${CONTEXT} -n ${namespace} | grep -w ${service} -q ; then
    helm upgrade -i ${service}  zhonglun/dubbo-service   ${options} --kube-context ${CONTEXT} -n ${namespace}
    #else
    #    helm install  ${service}  zhonglun/dubbo-service   ${options} --kube-context ${CONTEXT} -n ${namespace}
    #fi
    kubectl --context ${CONTEXT} get deploy ${service}  -o wide  -n ${namespace}
}

function deploy_to_hwk8s(){
    if [[ $# -eq 2 ]] ; then
      service=${serviceName}-$1
      replics=$2
    else
       service=${serviceName}
       replics=$1
    fi
    resource=$(eval echo '$'${ENV}_"$(echo ${service}|tr -s "-" "_")_conf")
    image=${REGISTRY_NET}/zhonglun/${service}:${ENV}_${BUILD_NUMBER}_${SVN_REVISION_2}
    namespace=${ENV}
    if [[ -n $resource ]];then
        cpu=$(echo ${resource}|awk '{print $1}')
        memory=$(echo ${resource}|awk '{print $2}')
        options="--set  imagename=${image},replics=${replics},name=${service},cpu=${cpu},memory=${memory},namespace=${namespace}"
    else
        options="--set  imagename=${image},replics=${replics},name=${service},namespace=${namespace}"
    fi
    
    helm repo update
    helm upgrade -i ${service}  huawei/huawei   ${options}  ${CONTEXTHW} -n ${namespace}
    kubectl ${CONTEXTHW} get deploy ${service}  -o wide  -n ${namespace}
}

 case ${serviceName} in
        "zkmsv5")
          deploy_to_k8s $1
          deploy_to_hwk8s $1
        ;;
        "fpv5"|"openv5"|"fmsv5"|"mcmsv5"|"umsv5")
          deploy_to_k8s web $1
          deploy_to_hwk8s web $1
        ;;
        "wsms"|"wsmsv5")
          deploy_to_k8s admin $1
        ;;
        *) 
          deploy_to_k8s web     $1
          deploy_to_k8s admin   $2
          deploy_to_hwk8s web $1
          deploy_to_hwk8s admin $2
        ;;
 esac

declare -i SUM=0;
while [[ $SUM -lt 20 ]];do
    sleep 3
    if kubectl ${CONTEXTHW} get pods -n $ENV | grep -w ^${serviceName} | grep ContainerCreating || kubectl --context ${CONTEXT} get pods -n $ENV | grep -w ^${serviceName} | grep ContainerCreating; then
        sleep 10
    #else
    #    kubectl ${CONTEXTHW} get pods -n $ENV | grep -w ^${serviceName}
    else
        for new_pod in $(kubectl --context=${CONTEXT} get  deployment -n $ENV | grep -w ${serviceName} | awk '{print $1}');do
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
echo "程序部署中，请等待1分钟..."

