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

    # find the right image name and branch in prodv5 k8s cluster

    image=$(kubectl get deploy ${service}  -n prodv5  --context prodv5  -o jsonpath={.spec.template.spec.containers[0].image} )
    if [ -n "$image" ] ;
    then
         branch=$(kubectl get deploy ${service}  -n prodv5  --context prodv5  -o jsonpath={.metadata.labels.version} )
    else      
      echo "fail to find the valid image"
      exit 10
    fi


    #branch=$(kubectl get deploy ${service}  -n ${ENV}gray  --context gray  -o jsonpath={.metadata.labels.version} )
    #resource=$(eval echo '$'${ENV}_"$(echo ${service}|tr -s "-" "_")_conf")
    ENVPRODV5="prodv5"   
    # use the same cpu/memory config for prodv5 environment set in jenkins 

    resource=$(eval echo '$'${ENVPRODV5}_"$(echo ${service}|tr -s "-" "_")_conf")
   # resource=$(eval echo '$'${ENVV5}_"$(echo ${service}|tr -s "-" "_")_conf")

    namespace=${ENV}
    if [[ -n $resource ]];then
        cpu=$(echo ${resource}|awk '{print $1}') 
        memory=$(echo ${resource}|awk '{print $2}')
        options="--set  imagename=${image},replics=${replics},name=${service},cpu=${cpu},memory=${memory},namespace=${namespace},version=${branch}"
    else
        options="--set  imagename=${image},replics=${replics},name=${service},namespace=${namespace},version=${branch}"
    fi
    helm repo update
    helm upgrade -i ${service}  vip/dubbo-service-vip   ${options} --kube-context ${CONTEXT} -n ${namespace}
    kubectl --context ${CONTEXT} get deploy ${service}  -o wide  -n ${namespace}

}

 case ${serviceName} in
        "zkms"|"dwms"|"zkmsv5"|"dwmsv5"|"dvmsv5")
          deploy_to_k8s $1
        ;;
        "fp"|"basic"|"entry"|"api"|"fms"|"jxms"|"chms"|"ums"|"wxdatasv5"|"fpv5"|"basicv5"|"entryv5"|"fpapiv5"|"fmsv5"|"umsv5"|"mcmsv5"|"opmsv5"|"apiv5"|"openv5"|"tiomsv5"|"qlms")
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
    if kubectl --context=${CONTEXT} get pods -n $ENV | grep -w ${serviceName} | grep ContainerCreating ; then
        sleep 10
    else
        for new_pod in $(kubectl --context=${CONTEXT} get  deployment -n $ENV | grep -w ${serviceName} | awk '{print $1}');do
              while true;do
		if [[ ${CONTEXT} == prodv5 ]];then
                      printf "\e[43;30m点击链接查看启动日志;(登录账号:k8slogs@1399783668292805.onaliyun.com  登录密码:Password1234) \e[0m\n"
                      printf "\e[4;42m https://cs.console.aliyun.com/?spm=5176.12818093.ProductAndService--ali--widget-home-product-recent.dre5.5adc16d0w6H8Ta#/k8s/cluster/c222bb6f0baa641d6b0e1fc16426c2fb9/v2/workload/deployment/detail/prodv5/${new_pod}/pods?type=deployment&clusterType=ManagedKubernetes&profile=Default&state=running&ns=prodv5&region=cn-shanghai \e[0m\n"
#                      printf "\e[43;30m 第一次使用,点击 http://192.168.1.149:9000/doc/jenkins.html  查看具体使用说明。 \e[0m\n"
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

