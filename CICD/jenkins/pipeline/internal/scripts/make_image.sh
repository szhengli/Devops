#!/usr/bin/bash

function make_image(){
    [[ $# -eq 1 ]] && service=${serviceName}-$1 || service=${serviceName}
    #image=${REGISTRY}/zhonglun/${service}:${BUILD_NUMBER}_${SVN_REVISION} 
    #env=$(echo ${JOB_BASE_NAME} | awk -F '-'  '{ print $1 }')
    if [[ $CONTEXT = zl ]];then
	docker login ${testdev_CREDENTIALS}  ${testdev_REGISTRY}
#        image=${testdev_REGISTRY}/zhonglun/${service}:${ENV}_${BUILD_NUMBER}_${SVN_REVISION}
        image=${testdev_REGISTRY}/zlnet/${ENV}/${service}:${BUILD_NUMBER}_${SVN_REVISION}
    else
	docker login ${CREDENTIALS}  ${REGISTRY}
        image=${REGISTRY}/zlnet/${service}:${ENV}_${BUILD_NUMBER}_${SVN_REVISION} 
    fi
   echo "************************************************make_image"
   pwd
   ls -l
   cd /zlpt_jkwk/workspace/${JOB_BASE_NAME}/${service}/target

   # cd /var/lib/jenkins/workspace/${JOB_BASE_NAME}/${service}/target
#    cd /zlpt_jkwk/${env}/${serviceName}/${service}/target
    cp  -r /k8s/scripts    ./
    cp /k8s/Dockerfile ./
    cp /k8s/pinpoint.tar.gz ./
    ls -l 
    docker build --build-arg jar=${service}-1.0.0-exec.jar --build-arg pro_name=${service} --build-arg sv_name=${serviceName} --build-arg sv_env=${ENV} -t ${image} .
    if docker push  ${image} ; then
        echo "push to ali registry"
	docker rmi ${image}
    else
        echo "fail to create image on registry"
	docker rmi ${image}
        exit 1
    fi
}
case ${serviceName} in
    "zkms"|"zkmsv5"|"dwms"|"dwmsv5")
        make_image  
    ;;
    "fp"|"fpapiv5"|"basic"|"entry"|"entryv5"|"api"|"apiv5"|"fms"|"fmsv5"|"jxms"|"chms"|"chmsv5"|"ums"|"umsv5"|"mcms"|"mcmsv5"|"fpv5"|"basicv5"|"opmsv5")
        make_image web 
    ;;
    "wsms"|wsmsv5)
        make_image admin 
    ;;
    *) 
        make_image web 
        make_image admin 
    ;;
esac

