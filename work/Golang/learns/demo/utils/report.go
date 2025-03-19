package utils

import (
	"bytes"
	"fmt"
	"text/template"
)

func PrepareReport() *DingTalkMarkdownMessage {
	var buff bytes.Buffer
	// Create a new template
	tmpl, err := template.New("example").Parse(ReportTemplate)
	if err != nil {
		fmt.Println("Error parsing template:", err)
		return nil
	}

	content := GetAlertReport()

	err = tmpl.Execute(&buff, content)
	if err != nil {
		fmt.Println("Error executing template:", err)
	}

	report := buff.String()

	fmt.Println(report)
	return &DingTalkMarkdownMessage{
		Msgtype: "markdown",
		Markdown: &Markdown{
			Title: "运维周报",
			Text:  report,
		},
		At: &At{
			AtMobiles: []string{"18812345678"}, // 需要@的手机号
			IsAtAll:   false,
		},
	}
}
