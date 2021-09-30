#!/bin/bash

Service_Name=$2
Env=$1

Server_IP=()
Server_IP_web=()  
Server_IP_admin=()
Max_Hosts=30

function get_Test_list(){
    name=$1   #  web or admin
    if [ $name ];then 
      if [ $Env != "prod" ]; then
          eval echo ${Env}-${Service_Name}-${name}-{1..${Max_Hosts}}.zl.test
      else
          eval echo ${Service_Name}-${name}-{1..${Max_Hosts}}.zl.local 
      fi
    else
      if [ $Env != "prod" ]; then
          eval echo ${Env}-${Service_Name}-{1..${Max_Hosts}}.zl.test
      else
          eval echo ${Service_Name}-{1..${Max_Hosts}}.zl.local 
      fi
    fi
}



function get_hostlist(){
    Test_List=$(get_Test_list web)
    for host in $Test_List;do
#        if ping ${host} -c3 &>/dev/null;then
        if nslookup ${host} &>/dev/null; then
            Server_IP_web[${#Server_IP_web[*]}]=${host}
        else
            break
        fi
    done
    Test_List=$(get_Test_list admin)
    for host in $Test_List;do
#        if ping ${host} -c3 &>/dev/null;then
        if nslookup ${host} &>/dev/null; then
            Server_IP_admin[${#Server_IP_admin[*]}]=${host}
        else
            break
        fi
    done
    Test_List=$(get_Test_list)
    for host in $Test_List;do
#        if ping ${host} -c3 &>/dev/null;then
        if nslookup ${host} &>/dev/null; then
            Server_IP[${#Server_IP[*]}]=${host}
        else
            break
        fi
    done
    
}

function deploy_service(){
    name=$1   #admin or web
    jarfile="${Service_Name}-${name}-1.0.0-exec.jar"
    eval hosts=\${Server_IP_$name[*]}
    echo "需要部署的${Service_Name}-${name}主机列表: ${hosts[*]}"
    cd ${WORKSPACE}/${Env}/${Service_Name}/${Service_Name}-${name}/target
    for node in ${hosts};do
        if scp ${jarfile} ${node}:/data/ ; then
            echo "拷贝代码 ${Service_Name}-${name} 包到目标主机 ${node} 成功...."
            if ssh ${node} "bash -x /data/start.sh ${jarfile}" ; then
                echo "${Service_Name}-${name}服务在${node}节点上部署成功!"
            else
                echo "${Service_Name}-${name}服务在${node}节点上部署失败!"
                exit 1
            fi
        else
            echo "${Service_Name}-${name}服务在${node}节点上部署失败!"
            exit 1
        fi
    done
}

function deploy_tomcat(){
    name=$1
    warfile="${Service_Name}-${name}-1.0.0.war"
    eval hosts=\${Server_IP[*]}
    echo "需要部署的${Service_Name}主机列表: ${hosts[*]}"
    cd ${WORKSPACE}/${Env}/${Service_Name}/${Service_Name}-${name}/target
    for node in ${hosts};do
        if scp ${warfile} ${node}:/data/apache-tomcat/ ; then
            echo "拷贝代码 ${Service_Name}-${name} 包到目标主机 ${node} 成功...."
            if ssh ${node} "bash -x /data/restart.sh" ; then
                echo "${Service_Name}服务在${node}节点上部署成功!"
            else
                echo "${Service_Name}服务在${node}节点上部署失败!"
                exit 1
            fi
        else
            echo "${Service_Name}服务在${node}节点上部署失败!"
            exit 1
        fi
    done
}

function deploy_single(){
    jarfile="${Service_Name}-1.0.0-exec.jar"
    eval hosts=\${Server_IP[*]}
    echo "需要部署的${Service_Name}主机列表: ${hosts[*]}"
    cd ${WORKSPACE}/${Env}/${Service_Name}/${Service_Name}/target
    for node in ${hosts};do
        if scp ${jarfile} ${node}:/data/ ; then
            echo "拷贝代码 ${Service_Name}包到目标主机 ${node} 成功...."
            if ssh ${node} "bash -x /data/start.sh ${jarfile}" ; then
                echo "${Service_Name}服务在${node}节点上部署成功!"
            else
                echo "${Service_Name}服务在${node}节点上部署失败!"
                exit 1
            fi
        else
            echo "${Service_Name}服务在${node}节点上部署失败!"
            exit 1
        fi
    done
}

main(){
    get_hostlist
    echo "${Server_IP_web[*]}"
    echo "${Server_IP_admin[*]}"
    echo "${Server_IP[*]}"
    case ${Service_Name} in
        "basic"|"api"|"entry"|"wsms")
         deploy_tomcat web
        ;;
        "zkms"|"dwms")
         deploy_single
        ;;
        "fp"|"jxms")
         deploy_service web
        ;;
        "jobms")
         deploy_service admin
        ;;
        *) 
         deploy_service web
         deploy_service admin
        ;;
    esac
}

main $1 $2
