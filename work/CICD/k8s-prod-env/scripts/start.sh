#!/usr/bin/bash
Service_name=`echo $(hostname)|awk -F"-" '{print $1"-"$2}'`
JVMS="-server ${JAVA_OPTS} -XX:MetaspaceSize=200m -XX:MaxMetaspaceSize=256m \
        -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled \
        -XX:+ExplicitGCInvokesConcurrentAndUnloadsClasses -XX:+PrintGCTimeStamps \
        -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=68 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -DisPod=true \
        -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/dump/oom/$(hostname)_oomdump_$(date +%Y%m%d%H%M).hprof \
	-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Ddubbo.shutdown.hook=true"


if [ $ENV == "prodv5gray" ]; then
  exec java  ${JVMS} -Dcsp.sentinel.dashboard.server=sentinel.devops.svc.cluster.local -Dproject.name=${Service_name} -DrouteTag=gray  -jar $JAR
elif [ $ENV == "vip" ]; then
  exec java  ${JVMS} -Dcsp.sentinel.dashboard.server=sentinel.devops.svc.cluster.local -Dproject.name=${Service_name} -DrouteTag=vip  -jar $JAR
else
  exec java  ${JVMS} -Dcsp.sentinel.dashboard.server=sentinel.devops.svc.cluster.local -Dproject.name=${Service_name}  -jar $JAR
fi

