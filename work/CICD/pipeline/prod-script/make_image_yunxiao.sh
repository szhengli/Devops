#!/usr/bin/bash

function make_image(){
    service=yunxiao
    docker login ${CREDENTIALS}  ${REGISTRY}
    image=${REGISTRY}/zhonglun/${service}:${ENV}_${BUILD_NUMBER}_${SVN_REVISION}
    echo "************************************************make_image"
    pwd
    ls -l
    cd /tmp/build

    cp -f -r /k8s/scripts    ./
    cp -f -r /yunxiao/* ./
    ls -l 
    docker build --build-arg sv_env=${ENV} -t ${image} .
    if docker push  ${image} ; then
        echo "push to ali registry"
	docker rmi ${image}
    else
        echo "fail to create image on registry"
	docker rmi ${image}
        exit 1
    fi
    rm -rf /tmp/build/scripts
}


for app_name in {yunxiao-admin,yunxiao-web,yunxiao-job};do
    if [[ ${app_name} = yunxiao-admin ]];then
        cd /zlpt_jkwk/workspace/${JOB_BASE_NAME}/${app_name}/target && cp admin-0.1.0-SNAPSHOT.jar /tmp/build/admin/ && cp -f /yunxiao/application-prod.properties.admin /tmp/build/admin/application-prod.properties
    elif [[ ${app_name} = yunxiao-web ]];then
        cd /zlpt_jkwk/workspace/${JOB_BASE_NAME}/${app_name}/target && cp yunxiao.jar /tmp/build/web/ && cp -f /yunxiao/application-prod.properties.web /tmp/build/web/application-prod.properties
    else
        cd /zlpt_jkwk/workspace/${JOB_BASE_NAME}/${app_name}/target && cp job-0.0.1-SNAPSHOT.jar /tmp/build/job/ 
    fi
done

make_image

