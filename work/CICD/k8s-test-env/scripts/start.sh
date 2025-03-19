#!/bin/bash
if [[ $SV_ENV == prev5 || $SV_ENV == pre || $SV_ENV == sitv5 || $SV_ENV == sit || $SV_ENV == fat || $SV_ENV == fatv5 ]];then
        JVMS="-server ${JAVA_OPTS} -XX:MetaspaceSize=200m -XX:MaxMetaspaceSize=256m \
                -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled \
                -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=68 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -DisPod=true \
                -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true"
        exec java -javaagent:skywalking-agent/skywalking-agent.jar -Dskywalking.agent.service_name=${SV_ENV}-${PRO_NAME} ${JVMS} -jar $JAR
#        exec java ${JVMS} -jar $JAR
else
	JVMS="-server ${JAVA_OPTS} -XX:MetaspaceSize=200m -XX:MaxMetaspaceSize=256m \
		-XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -XX:+PrintHeapAtGC -Xloggc:/data/gclogs/${SV_ENV}-$HOSTNAME.log \
		-XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=68 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -DisPod=true \
		-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true"
#	exec java -javaagent:pinpoint/pinpoint-bootstrap-2.2.2.jar -Dpinpoint.agentId=${SV_ENV}-${PRO_NAME} -Dpinpoint.applicationName=${SV_ENV}-${PRO_NAME} ${JVMS} -jar $JAR
#       exec java ${JVMS} -jar $JAR
        exec java -javaagent:skywalking-agent/skywalking-agent.jar -Dskywalking.agent.service_name=${SV_ENV}-${PRO_NAME} ${JVMS} -jar $JAR
fi
