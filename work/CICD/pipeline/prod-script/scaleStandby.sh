#!/usr/bin/bash

for service in  $( kubectl get deploy   -n prodv5 --context standby  | grep -v NAME | awk '{ print $1}' ) 
do
    max=$(kubectl get hpa  -n prodv5 --context standby  ${service}-hpa   -o jsonpath='{.spec.maxReplicas}' )    
   if min=$((max/2)) 
   then
          kubectl patch  hpa  -n prodv5 --context standby  ${service}-hpa   -p  '{"spec": {"minReplicas":'${min}'}}'
   fi

done
