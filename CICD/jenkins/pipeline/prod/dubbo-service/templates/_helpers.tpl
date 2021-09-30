{{ define "dwms.hosts.prod" }}
hostAliases:
- ip: "172.19.233.240"
  hostnames:
  - "emr-worker-7.cluster-177469"
  - "emr-worker-7"
- ip: "172.19.233.241"
  hostnames:
  - "emr-worker-8.cluster-177469"
  - "emr-worker-8"
- ip: "172.19.233.236"
  hostnames:
  - "emr-worker-3.cluster-177469"
  - "emr-worker-3"
- ip: "172.19.233.235"
  hostnames:
  - "emr-worker-2.cluster-177469"
  - "emr-worker-2"
- ip: "172.19.233.234"
  hostnames:
  - "emr-worker-1.cluster-177469"
  - "emr-worker-1"
- ip: "172.19.233.238"
  hostnames:
  - "emr-worker-5.cluster-177469"
  - "emr-worker-5"
- ip: "172.19.233.239"
  hostnames:
  - "emr-worker-6.cluster-177469"
  - "emr-worker-6"
- ip: "172.19.233.237"
  hostnames:
  - "emr-worker-4.cluster-177469"
  - "emr-worker-4"
- ip: "172.19.233.232"
  hostnames:
  - "emr-header-1.cluster-177469"
  - "emr-header-1"
- ip: "172.19.233.231"
  hostnames:
  - "emr-header-2.cluster-177469"
  - "emr-header-2"
- ip: "172.19.233.233"
  hostnames:
  - "emr-header-3.cluster-177469"
  - "emr-header-3"
{{- end }}

{{ define "dwms.hosts.test" }}
hostAliases:
- ip: "192.168.3.235"
  hostnames:
  - "ambari"
- ip: "192.168.3.236"
  hostnames:
  - "hadoop236"
- ip: "192.168.3.237"
  hostnames:
  - "hadoop237"
- ip: "192.168.3.238"
  hostnames:
  - "hadoop238"
- ip: "192.168.3.239"
  hostnames:
  - "hadoop239"
- ip: "192.168.3.46"
  hostnames:
  - "zluat46"
- ip: "192.168.3.47"
  hostnames:
  - "zluat47"
- ip: "192.168.3.48"
  hostnames:
  - "zluat48"
- ip: "192.168.3.49"
  hostnames:
  - "zluat49"
- ip: "192.168.3.50"
  hostnames:
  - "zluat50"
- ip: "192.168.3.51"
  hostnames:
  - "zluat51"
- ip: "192.168.3.52"
  hostnames:
  - "zluat52"
- ip: "192.168.3.53"
  hostnames:
  - "zluat53"
- ip: "192.168.3.54"
  hostnames:
  - "zluat54"
- ip: "192.168.3.55"
  hostnames:
  - "zluat55"
{{- end }}

{{ define "vipv5.logs" }}
- name: aliyun_logs_vip-service-hm
  value: /data/app-logs/*.vip.service-hm.log.*
- name: aliyun_logs_vip-service-hm_project
  value: vip-service-monitor-zl
- name: aliyun_logs_vip-service-hm_logstore
  value: service-monitor
- name: aliyun_logs_vip-service-hm_machinegroup
  value: service-monitor
- name: aliyun_logs_vip-zllog
  value: /data/app-logs/*.vip.hm.log.*
- name: aliyun_logs_vip-zllog_project
  value: vip-app-logs-datas-zl
- name: aliyun_logs_vip-zllog_logstore
  value: zllog
- name: aliyun_logs_vip-zllog_machinegroup
  value: vip-hm-group
- name: aliyun_logs_{{ .Values.name }}
  value: /data/app-logs/{{ .Values.name }}.vip.log.*
- name: aliyun_logs_{{ .Values.name }}_project
  value: vip-app-logs-zl
- name: aliyun_logs_{{ .Values.name }}_logstore
  value: {{ .Values.name }}
- name: aliyun_logs_{{ .Values.name }}_machinegroup
  value: vip-log-group
{{- end }}

{{ define "prod.logs" }}
- name: aliyun_logs_prod-service-hm
  value: /data/app-logs/*.prod.service-hm.log.*
- name: aliyun_logs_prod-service-hm_project
  value: service-monitor
- name: aliyun_logs_prod-service-hm_logstore
  value: service-monitor
- name: aliyun_logs_prod-service-hm_machinegroup
  value: service-monitor
- name: aliyun_logs_prod-zllog
  value: /data/app-logs/*.prod.hm.log.*
- name: aliyun_logs_prod-zllog_project
  value: app-logs-datas-zl
- name: aliyun_logs_prod-zllog_logstore
  value: zllog
- name: aliyun_logs_prod-zllog_machinegroup
  value: prod-hm-group
- name: aliyun_logs_{{ .Values.name }}
  value: /data/app-logs/{{ .Values.name }}.prod.log.*
- name: aliyun_logs_{{ .Values.name }}_project
  value: app-logs-zl
- name: aliyun_logs_{{ .Values.name }}_logstore
  value: {{ .Values.name }}
- name: aliyun_logs_{{ .Values.name }}_machinegroup
  value: prod-log-group
{{- end }}

{{ define "prodv5.logs" }}
- name: aliyun_logs_prod-service-hm
  value: /data/app-logs/*.prod.service-hm.log.*
- name: aliyun_logs_prod-service-hm_project
  value: service-monitor
- name: aliyun_logs_prod-service-hm_logstore
  value: service-monitor
- name: aliyun_logs_prod-service-hm_machinegroup
  value: service-monitor
- name: aliyun_logs_prodv5-zllog
  value: /data/app-logs/*.prod.hm.log.*
- name: aliyun_logs_prodv5-zllog_project
  value: prodv5-app-logs-datas-zl
- name: aliyun_logs_prodv5-zllog_logstore
  value: zllog
- name: aliyun_logs_prodv5-zllog_machinegroup
  value: prodv5-hm-group
- name: aliyun_logs_{{ .Values.name }}
  value: /data/app-logs/{{ .Values.name }}.prod.log.*
- name: aliyun_logs_{{ .Values.name }}_project
  value: app-logs-zl
- name: aliyun_logs_{{ .Values.name }}_logstore
  value: {{ .Values.name }}
- name: aliyun_logs_{{ .Values.name }}_machinegroup
  value: prod-log-group
{{- end }}

{{- define "hpa" }}
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Values.name }}
  labels:
    app: {{ .Values.name }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Values.name }}
  minReplicas: {{ .Values.replics }}
  maxReplicas: {{ .Values.replics | mul 2 }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      targetAverageUtilization: 300
  - type: Resource
    resource:
      name: memory
      targetAverageUtilization: 150
{{- end }}
