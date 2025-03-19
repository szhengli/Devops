#!/usr/bin/bash
set -x
function deploy_to_k8s(){
    service=yunxiao
    replics=$1
    namespace=${ENV}
    helm repo update
    if [[ $CONTEXT = prod ]]; then
	image=${REGISTRY}/zhonglun/${service}:${ENV}_${BUILD_NUMBER}_${SVN_REVISION}
        options=" --set  imagename=${image},replics=${replics},name=${service},namespace=${namespace}"
	helm upgrade -i ${service}  yunxiao-service/yunxiao-service  ${options} --kube-context ${CONTEXT} -n ${namespace}
    else
	      echo "CONTEXT ERROR"
    fi

    kubectl --context ${CONTEXT} get deploy ${service}  -o wide  -n ${namespace}
}
deploy_to_k8s $1

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

