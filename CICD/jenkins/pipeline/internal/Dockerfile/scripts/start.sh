#!/bin/bash
if [[ $SV_ENV == sit ]];then
	JVMS="-server -Xms1g -Xmx1g -Xmn256m -Xss256k -XX:MetaspaceSize=200m -XX:MaxMetaspaceSize=256m \
		-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -XX:+DisableExplicitGC \
		-XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=68 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps \
		-Ddubbo.registry.file=/data/.dubbo/dubbo-registry-$(date +%Y%m%d-%H%M%S).cache \
		-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Ddubbo.shutdown.hook=true"
	exec java -javaagent:pinpoint/pinpoint-bootstrap-2.2.2.jar -Dpinpoint.agentId=${SV_ENV}-${PRO_NAME} -Dpinpoint.applicationName=${SV_ENV}-${PRO_NAME} ${JVMS} -jar $JAR
else
	JVMS="-server -Xms1g -Xmx1g -Xmn256m -Xss256k -XX:MetaspaceSize=200m -XX:MaxMetaspaceSize=256m \
		-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -XX:+DisableExplicitGC \
		-XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=68 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps \
		-Ddubbo.registry.file=/data/.dubbo/dubbo-registry-$(date +%Y%m%d-%H%M%S).cache \
		-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Ddubbo.shutdown.hook=true"
	exec java ${JVMS} -jar $JAR
fi
