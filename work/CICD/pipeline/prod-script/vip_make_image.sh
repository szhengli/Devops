#!/usr/bin/bash

function make_image(){
    [[ $# -eq 1 ]] && service=${serviceName}-$1 || service=${serviceName}
    docker login ${CREDENTIALS}  ${REGISTRY} 
    #image=${REGISTRY}/zhonglun/${service}:${BUILD_NUMBER}_${SVN_REVISION} 
   # env=$(echo ${JOB_BASE_NAME} | awk -F '-'  '{ print $1 }')
   image=${REGISTRY}/zhonglun/${service}:${ENV}_${BUILD_NUMBER}_${SVN_REVISION_2} 
   echo "************************************************make_image"
   pwd
   ls -l
   #cd /zlpt_jkwk/workspace/${JOB_BASE_NAME}/${service}/target
   cd ${service}/target
   # cd /var/lib/jenkins/workspace/${JOB_BASE_NAME}/${service}/target
#    cd /zlpt_jkwk/${env}/${serviceName}/${service}/target
    cp  -r /vipk8s/scripts    ./
    cp /vipk8s/Dockerfile ./
    #cp /k8s/agent.tar.gz ./
    ls -l 
    docker build --build-arg jar=${service}-1.0.0-exec.jar  -t ${image} . 
    cd ../../  #在第一个服务部署完后回到job的工作目录
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
    "zkms"|"dwms"|"zkmsv5"|"dwmsv5"|"dvmsv5")
        make_image  
    ;;
    "fp"|"basic"|"entry"|"api"|"fms"|"jxms"|"chms"|"ums"|"wxdatasv5"|"fpv5"|"basicv5"|"entryv5"|"fpapiv5"|"fmsv5"|"umsv5"|"mcmsv5"|"opmsv5"|"apiv5"|"openv5"|"tiomsv5"|"qlms")
        make_image web 
    ;;
    #"wsms"|"wsmsv5")
    #    make_image admin 
    #;;
    *) 
        make_image web 
        make_image admin 
    ;;
esac
