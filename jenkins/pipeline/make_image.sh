#!/usr/bin/bash

function make_image(){
    [[ $# -eq 1 ]] && service=${serviceName}-$1 || service=${serviceName}
    docker login ${CREDENTIALS}  ${REGISTRY} 
    image=${REGISTRY}/zhonglun/${service}:${BUILD_NUMBER}_${SVN_REVISION} 
    env=$(echo ${JOB_BASE_NAME} | awk -F '-'  '{ print $1 }')
    cd /var/lib/jenkins/workspace/${JOB_BASE_NAME}/${service}/target
#    cd /zlpt_jkwk/${env}/${serviceName}/${service}/target
    cp  -r /k8s/scripts    ./
    cp /k8s/Dockerfile ./
    ls -l 
    docker build --build-arg jar=${service}-1.0.0-exec.jar  -t ${image} . 
    if docker push  ${image} ; then
        echo "push to ali registry"
    else
        echo "fail to create image on registry"
        exit 1
    fi
}

case ${serviceName} in
    "zkms"|"dwms")
        make_image  
    ;;
    "fp")
        make_image web 
    ;;
    "jobms")
        make_image admin 
    ;;
    *) 
        make_image web 
        make_image admin 
    ;;
esac
