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
    #resource=$(eval echo '$'"$(echo ${service}|tr -s "-" "_")_conf")
    resource=$(eval echo '$'${ENV}_"$(echo ${service}|tr -s "-" "_")_conf")
    image=${REGISTRY}/zhonglun/${service}:${ENV}_${BUILD_NUMBER}_${SVN_REVISION}
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

 case ${serviceName} in
        "zkms"|"dwms"|"zkmsv5"|"dwmsv5")
          deploy_to_k8s $1
        ;;
        "fp"|"basic"|"entry"|"api"|"fms"|"jxms"|"chms"|"ums"|"mcms"|"fpv5"|"basicv5"|"entryv5"|"fpapiv5"|"fmsv5"|"chmsv5"|"umsv5"|"mcmsv5"|"opmsv5")
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
 echo "程序部署中，请等待1分钟..."
