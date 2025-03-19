#!/usr/bin/bash
set -x
CONTEXTTEST="--kubeconfig /root/.kube/test"
function deploy_to_k8s(){
    if [[ $# -eq 2 ]] ; then
      service=${serviceName}-$1
      replics=$2
    else  
       service=${serviceName}
       replics=$1
    fi
    resource=$(eval echo '$'${ENV}_"$(echo ${service}|tr -s "-" "_")_conf")
    image=${REGISTRY}/zhongluntest/${service}:${ENV}_${BUILD_NUMBER}_${SVN_REVISION}
    namespace=${ENV}
    if [[ -n $resource ]];then
        cpu=$(echo ${resource}|awk '{print $1}') 
        memory=$(echo ${resource}|awk '{print $2}')
        options="--set  imagename=${image},replics=${replics},name=${service},cpu=${cpu},memory=${memory},namespace=${namespace}"
    else
        options="--set  imagename=${image},replics=${replics},name=${service},namespace=${namespace}"
    fi
    helm repo update
    helm upgrade -i ${service}  test-service/dubbo-service   ${options} ${CONTEXTTEST} -n ${namespace}
    kubectl ${CONTEXTTEST} get deploy ${service}  -o wide  -n ${namespace}
}

 case ${serviceName} in
        "zkms"|"dwms"|"zkmsv5"|"dwmsv5")
          deploy_to_k8s $1
        ;;
        "fp"|"basic"|"entry"|"api"|"fms"|"jxms"|"chms"|"ums"|"mcms"|"fpv5"|"basicv5"|"entryv5"|"fpapiv5"|"fmsv5"|"chmsv5"|"umsv5"|"mcmsv5"|"opmsv5"|"apiv5"|"openv5"|"urmsv5")
          deploy_to_k8s web $1
        ;;
        "wsms"|"wsmsv5")
          deploy_to_k8s admin $1
        ;;
        *) 
          deploy_to_k8s web     $1
          deploy_to_k8s admin   $2
        ;;
 esac

declare -i SUM=0;
while [[ $SUM -lt 20 ]];do
    sleep 3
    if kubectl ${CONTEXTTEST} get pods -n $ENV | grep -w ${serviceName} | grep ContainerCreating ; then
        sleep 10
    else
        for new_pod in $(kubectl ${CONTEXTTEST} get  deployment -n $ENV | grep -w ${serviceName} | awk '{print $1}');do
              while true;do
		if [[ ${CONTEXT} == prodv5 ]];then
                    printf "\e[43;30m点击链接查看启动日志;(登录账号:k8slogs@1399783668292805.onaliyun.com  登录密码:Password1234) \e[0m\n"
                    printf "\e[4;42m https://cs.console.aliyun.com/?spm=5176.12818093.ProductAndService--ali--widget-home-product-recent.dre5.5adc16d0w6H8Ta#/k8s/cluster/c222bb6f0baa641d6b0e1fc16426c2fb9/v2/workload/deployment/detail/prodv5/${new_pod}/pods?type=deployment&clusterType=ManagedKubernetes&profile=Default&state=running&ns=prodv5&region=cn-shanghai \e[0m\n"
#                      printf "\e[43;30m 第一次使用,点击 http://192.168.1.149:9000/doc/jenkins.html  查看具体使用说明。 \e[0m\n"
	        else
		    printf "\e[43;30m点击链接查看启动日志;(登录账号:k8slogs@1399783668292805.onaliyun.com  登录密码:Password1234) \e[0m\n"
                    printf "\e[4;42m https://cs.console.aliyun.com/?spm=5176.12818093.top-nav.31.455f16d0XpUJmh#/k8s/cluster/c03d4a035452146ffaf8a3bb056474ad0/v2/workload/deployment/detail/sit/${new_pod}/logs?type=deployment&clusterType=ManagedKubernetes&profile=Default&state=running&ns=sit&region=cn-shanghai \e[0m\n"
		fi
                      break
              done
        done
        break
    fi
    SUM=${SUM}+1
done
echo "程序部署中，请等待1分钟..."

