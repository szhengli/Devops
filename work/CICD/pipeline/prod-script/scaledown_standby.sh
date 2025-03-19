#!/usr/bin/bash

#serviceName=paysv5
#ENV=prodv5
#CONTEXT=standby

function scaledown(){
  deployName=$1
  kubectl scale --replicas=0 deployment $deployName  --context ${CONTEXT} -n ${ENV}  
}



case ${serviceName} in
        "zkms"|"dwms"|"zkmsv5"|"dwmsv5")
          scaledown ${serviceName} 
        ;;
        "fp"|"basic"|"entry"|"api"|"fms"|"jxms"|"chms"|"ums"|"mcms"|"fpv5"|"basicv5"|"entryv5"|"fpapiv5"|"fmsv5"|"umsv5"|"mcmsv5"|"opmsv5"|"apiv5"|"openv5"|"urmsv5")
          scaledown  ${serviceName}-web 
        ;;
        "wsms"|"wsmsv5")
          scaledown  ${serviceName}-admin
        ;;
        *)
          scaledown  ${serviceName}-web
          scaledown  ${serviceName}-admin
        ;;
esac

