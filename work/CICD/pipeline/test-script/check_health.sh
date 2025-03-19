#!/usr/bin/bash
set -x
web=$1
admin=$2
totalReplics=$((web+admin))
old_pod=`cat /tmp/pod/${ENV}-${serviceName}.txt`
currentPod=$(cat /data/${serviceName}-$ENV-currentPod.txt)
# remove the evicted pods record
kubectl delete pod   $(kubectl  get pod  -n ${ENV} | awk '/ ContainerStatusUnknown | OOMKilled |  Error/ {print $1}' ) -n ${ENV}  --force --grace-period 0  &>/dev/null
declare -i count=0;
while [[ $count -lt 60 ]]
do
    echo "!!!!!!!!!!!!!!!!!!!!!" 
    status=$(kubectl  get pod -l service=${serviceName} -n ${ENV} 2>/dev/null)
    declare -i crashs=0
    for new_pod in $(kubectl  get pod -l service=${serviceName} -n ${ENV} 2>/dev/null | awk 'NR>1{print $1}');do
    	if ! [[ "${old_pod}" =~ "${new_pod}" ]];then
            crash=`kubectl get pod ${new_pod} -n ${ENV} 2>/dev/null|grep "CrashLoopBackOff"|wc -l`
    	fi
        let crashs=$crashs+$crash
        echo "${crashs}"
    done
    if [ $crashs -ge 1 ];then
         break
    fi
    echo "---------------------------"
     if echo "${status}" | grep -v "Evicted" | grep -v "Terminating" | grep -q -E '0/1' ; then
        sleep 10
    else
        currentReplicas=$(echo "${status}"| grep "1/1     Running" -c)
        if [[  ${totalReplics} -eq "${currentReplicas}"  ]] ; then
           break
        fi
        sleep 2
    fi
    count=${count}+1
    echo "+++++++++++++++"
done

if [[ $count -lt  60 ]] ; then
    if [ $crashs -ge 1 ];then
	printf "\e[43;30m服务启动失败！请开发检查代码...\e[0m\n"
	echo ${currentPod}
	for new_pod in $(kubectl get pods -l service=${serviceName} -n $ENV | awk 'NR>1{print $1}');do
	    if ! [[ "${currentPod}" =~ "${new_pod}" ]];then
		printf "\e[43;30m点击链接查看启动日志 \e[0m\n"
		#printf "\e[4;42m https://rancher.cnzhonglunnet.com/p/c-s75t4:p-jsbxc/workloads/${ENV}:${new_pod} \e[0m\n"
		printf "\e[4;42m http://192.168.2.222/#/${ENV}_${new_pod} \e[0m\n"
	        python /usr/bin/dingding_pod.py "${ENV}_${new_pod}" ${serviceName} ${ENV} "服务启动失败"
		#printf "\e[43;30m 第一次使用,点击 http://192.168.1.149:9000/doc/jenkins.html  查看具体使用说明。 \e[0m\n"
	    fi
	done
        exit 1
    fi
    printf "\e[43;30m部署成功\e[0m\n"
else
    printf "\e[43;30m部署超时，可能失败\e[0m\n"
    exit 1
fi

