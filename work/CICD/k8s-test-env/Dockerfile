#FROM harbor.cnzhonglunnet.com/zhonglun/alpine-jdk1.8:v8
FROM harbor.cnzhonglunnet.com/zhonglun/centos7-zhonglun:v4.1
WORKDIR /data
ARG jar
COPY   $jar ./
ENV    JAR $jar
ARG  sv_env
ENV  SV_ENV $sv_env
ARG  pro_name
ENV  PRO_NAME $pro_name
#ADD  pinpoint.tar.gz ./
ADD  skywalking-agent.tar.gz ./
COPY   scripts/*.sh  /bin/
VOLUME  /data/app-logs
CMD ["start.sh"]
