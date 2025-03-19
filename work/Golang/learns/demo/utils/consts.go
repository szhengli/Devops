package utils

const (
	sqlTotalCount = `
		     select count(1) as total from zl_fpv5.fp_alerts   where 
			 alerttime>= concat(DATE_SUB(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 WEEK),' 00:00:00')
			 and   alerttime<=concat(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) + 1 DAY) ,' 23:59:59')
			 and alertname in (select alertname from zl_fpv5.fp_alertname) 
				 `
	sqlPCount = `
			SELECT  severity ,COUNT(1) AS count FROM zl_fpv5.fp_alerts   WHERE 
			 alerttime>= CONCAT(DATE_SUB(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 WEEK),' 00:00:00')
			 AND   alerttime<=CONCAT(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) + 1 DAY) ,' 23:59:59')
			 AND alertname IN (select alertname from zl_fpv5.fp_alertname) 
			GROUP BY   severity  ORDER BY severity
						`
	sqlAlertClass = `
			SELECT a.alertname AS name,COUNT(1) AS count FROM zl_fpv5.fp_alerts  a  WHERE    
			 a.alerttime>= CONCAT(DATE_SUB(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY), INTERVAL 1 WEEK),' 00:00:00')
			 AND   a.alerttime<=CONCAT(DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) + 1 DAY) ,' 23:59:59')
			 AND a.alertname IN (select alertname from zl_fpv5.fp_alertname) 
			GROUP BY a.alertname
				`

	dsn = "devlop_read:devlop_read@tcp(pc-uf6k532gavhs9j277.rwlb.rds.aliyuncs.com:3306)/zl_fpv5?charset=utf8mb4&parseTime=True&loc=Local"
	//### 运维报警周报告
	WebhookURL     = "https://oapi.dingtalk.com/robot/send?access_token=99ef304fcbe068513862c8f0fd48bae77011b1b0b845deaaf3e2fcf56db7dfc5"
	ReportTemplate = `![](https://zl-rancher-etcd-backup.oss-cn-shanghai.aliyuncs.com/ops/report1.png)
**时间范围:** {{ .FirstDay }} - {{ .LastDay }}
![](http://monitor.grafana.aliyuncs.com/render/d-solo/b4cb4b96-f376-40a0-9223-e01219384310/polardb?orgId=1&from={{ .FirstDayUnix }}&to={{ .FirstDayUnix }}&panelId=6&width=700&height=500&tz=Asia%2FShanghai)
**上周报警总数:** {{ .Total }}

**报警级别汇总:**
  - P1: <font color=red>{{ .P1 }} </font>
  - P2: <font color=#8B4513>{{ .P2 }} </font>
  - P3: <font color=blue>{{ .P3 }} </font>
  - P4: <font color=#008000>{{ .P4 }} </font>

**报警汇总：**
{{- range .Alerts }}
- {{ .Name }} : {{ .Count }}
{{- end}}

`
)
