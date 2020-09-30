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
    image=${REGISTRY}/zhonglun/${service}:${BUILD_NUMBER}_${SVN_REVISION} 
    options=" --set  imagename=${image},replics=${replics},name=${service}"
    helm repo update
    if helm list | grep ${service} -q ; then
       helm upgrade  ${service}  zhonglun/dubbo-service   ${options}
    else
       helm install  ${service}  zhonglun/dubbo-service   ${options} 
    fi
    kubectl get deploy ${service}  -o wide
}

 case ${serviceName} in
        "zkms"|"dwms")
          deploy_to_k8s $1
        ;;
        "fp")
          deploy_to_k8s web $1
        ;;
        "jobms")
          deploy_to_k8s admin $1
        ;;
        *) 
          deploy_to_k8s web     $1
          deploy_to_k8s admin   $2
        ;;
    esac
    echo "程序部署中，请等待1分钟..."

