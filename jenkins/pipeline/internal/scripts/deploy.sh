#!/usr/bin/bash
set -x
kubectl --context ${CONTEXT} get pod -l service=${serviceName} -n ${ENV} 2>/dev/null|awk 'NR>1{print $1}' > /tmp/pod/${ENV}-${serviceName}.txt
currentPod=$(kubectl get pods -l service=${serviceName} -n $ENV | awk 'NR>1{print $1}')
echo $currentPod > /data/${serviceName}-$ENV-currentPod.txt
function deploy_to_k8s(){
    if [[ $# -eq 2 ]] ; then
      service=${serviceName}-$1
      replics=$2
    else  
       service=${serviceName}
       replics=$1
    fi
    namespace=${ENV}
    helm repo update
    if [[ $CONTEXT = zl ]]; then
        image=${testdev_REGISTRY}/zlnet/${ENV}/${service}:${BUILD_NUMBER}_${SVN_REVISION}
        options=" --set  imagename=${image},replics=${replics},name=${service},namespace=${namespace}"
	helm upgrade -i ${service}  zhongluntest/dubbo-service   ${options} --kube-context ${CONTEXT} -n ${namespace}
    else
	echo "CONTEXT ERROR"
    fi

    kubectl --context ${CONTEXT} get deploy ${service}  -o wide  -n ${namespace}
}

 case ${serviceName} in
        "zkms"|"zkmsv5"|"dwms"|"dwmsv5")
          deploy_to_k8s $1
        ;;
        "fp"|"fpapiv5"|"fpv5"|"basic"|"basicv5"|"entry"|"entryv5"|"api"|"apiv5"|"fms"|"fmsv5"|"jxms"|"chms"|"chmsv5"|"ums"|"umsv5"|"mcms"|"mcmsv5"|"opmsv5")
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
    if kubectl get pods -l service=${serviceName} -n $ENV | grep ContainerCreating ; then
        sleep 10
    else
        for new_pod in $(kubectl get pods -l service=${serviceName} -n $ENV | awk 'NR>1{print $1}');do
            if ! [[ "${currentPod}" =~ "${new_pod}" ]];then
              while true;do
                  if kubectl get pods -n ${ENV} | grep ${new_pod} | grep  -q Running ; then
                      printf "\e[43;30m点击链接查看启动日志;(登录账号:devlop  登录密码:devlop) \e[0m\n"
                      printf "\e[4;42m https://rancher.cnzhonglunnet.com/p/c-s75t4:p-jsbxc/workloads/${ENV}:${new_pod} \e[0m\n"
                      printf "\e[43;30m 第一次使用,点击 http://192.168.1.149:9000/doc/jenkins.html  查看具体使用说明。 \e[0m\n"
                      break
                  fi
              done
            fi
        done
        break
    fi
    SUM=${SUM}+1
done

 echo "程序部署中，请等待1分钟..."

