#FROM harbor.cnzhonglunnet.com/zhonglun/alpine-jdk1.8:v8
FROM harbor.cnzhonglunnet.com/zhonglun/centos7-zhonglun:v4.1
WORKDIR /data
ARG jar
COPY   $jar ./
ENV    JAR $jar
COPY   scripts/*.sh  /bin/
VOLUME  /data/app-logs
CMD ["start.sh"]
