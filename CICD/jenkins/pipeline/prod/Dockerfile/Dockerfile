FROM registry-vpc.cn-shanghai.aliyuncs.com/zhonglun/centos7-zhonglun:v4.1
WORKDIR /data
ARG jar
COPY   $jar ./
ENV    JAR $jar
COPY   scripts/*.sh  /usr/bin/
VOLUME  /data/app-logs
CMD ["start.sh"]
