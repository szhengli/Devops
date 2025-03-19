#!/bin/bash
cd /data/job
nohup java -jar job-0.0.1-SNAPSHOT.jar --spring.profiles.active=sit &> /data/app-logs/job.log 2>&1 &
sleep 2
cd /data/admin
nohup java -jar admin-0.1.0-SNAPSHOT.jar --spring.profiles.active=sit &> /data/app-logs/admin.log 2>&1 &
sleep 2
cd /data/web/
exec java -jar yunxiao.jar --spring.profiles.active=sit

