#!/usr/bin/bash
Service_name=`echo $(hostname)|awk -F"-" '{print $1"-"$2}'`
if [[ $ENV == prod || $ENV == prodv5 ]];then
	JVMS="-server -Xms2g -Xmx4g -Xmn1g -Xss512k -XX:MetaspaceSize=200m -XX:MaxMetaspaceSize=256m \
	-XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -XX:+DisableExplicitGC \
	-XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=68 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps \
	-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/dump \
	-Ddubbo.registry.file=/data/.dubbo/dubbo-registry-$(date +%Y%m%d-%H%M%S).cache \
	-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Ddubbo.shutdown.hook=true"
else
    JVMS="-server -Xms512m -Xmx512m -Xmn256m -Xss256k -XX:MetaspaceSize=200m -XX:MaxMetaspaceSize=256m \
	-XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -XX:+DisableExplicitGC \
	-XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=68 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps \
	-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/dump \
	-Ddubbo.registry.file=/data/.dubbo/dubbo-registry-$(date +%Y%m%d-%H%M%S).cache \
	-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Ddubbo.shutdown.hook=true"
fi
exec java  ${JVMS} -jar $JAR
