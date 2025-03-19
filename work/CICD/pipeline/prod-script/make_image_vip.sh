#!/usr/bin/bash

function make_image(){
    [[ $# -eq 1 ]] && service=${serviceName}-$1 || service=${serviceName}
    docker login ${CREDENTIALS}  ${REGISTRY_VIP} 
   image=${REGISTRY_VIP}/zhonglun/${service}:${ENV}_${BUILD_NUMBER}_${SVN_REVISION_2} 
   echo "************************************************make_image"
   pwd
   ls -l
   cd ${service}/target
    cp  -r /vipk8s/scripts    ./
    cp /vipk8s/Dockerfile ./
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
    "zkmsv5"|"dwmsv5")
        make_image  
    ;;
    "fpv5"|"basicv5"|"entryv5"|"fpapiv5"|"fmsv5"|"umsv5"|"mcmsv5"|"opmsv5"|"apiv5"|"openv5"|"wxdatasv5")
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
