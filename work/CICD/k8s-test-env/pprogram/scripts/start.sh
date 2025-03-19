#!/bin/bash
JVMS="-server ${JAVA_OPTS} -XX:MetaspaceSize=200m -XX:MaxMetaspaceSize=256m \
      -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled \
      -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=68 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -DisPod=true \
      -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true"
exec java ${JVMS} -jar $JAR
