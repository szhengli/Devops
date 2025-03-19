package utils

import (
	"fmt"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"log"
	"os"
	"strconv"
	"time"
)

var (
	total          int
	alertsPCount   []AlertPCount
	alertNameCount []AlertNameCount
	alertReport    AlertReport
)

type AlertReport struct {
	Total, P1, P2, P3, P4     int
	FirstDay, LastDay         string
	FirstDayUnix, LastDayUnix string
	Alerts                    []AlertNameCount
}

type AlertPCount struct {
	Severity string `json:"severity"`
	Count    int    `json:"count"`
}

type AlertNameCount struct {
	Name  string `json:"name"`
	Count int    `json:"count"`
}

// Function to get the first and last day of the last week
func getFirstAndLastDayOfLastWeek() (string, string) {
	// Get today's date
	now := time.Now()

	// Find the current day of the week (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
	weekday := now.Weekday()

	// Calculate the date for the last Sunday
	lastSunday := now.AddDate(0, 0, -int(weekday+7)) // Go back to the previous Sunday
	// Calculate the date for the previous Saturday (6 days before the last Sunday)
	lastSaturday := lastSunday.AddDate(0, 0, 6)

	// Return the first and last day of last week
	return lastSunday.Format("2006-01-02"), lastSaturday.Format("2006-01-02")
}

func GetAlertReport() AlertReport {
	layout := "2006-01-02"

	// Convert to Unix timestamp (seconds since Unix epoch)
	alertReport.FirstDay, alertReport.LastDay = getFirstAndLastDayOfLastWeek()

	FirstDayTime, _ := time.Parse(layout, alertReport.FirstDay)
	LastDayTime, _ := time.Parse(layout, alertReport.LastDay)
	alertReport.FirstDayUnix = strconv.FormatInt(FirstDayTime.Unix(), 10)
	alertReport.LastDayUnix = strconv.FormatInt(LastDayTime.Unix(), 10)
	fmt.Println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	fmt.Println(alertReport.FirstDayUnix, alertReport.LastDayUnix)
	fmt.Println("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

	newLogger := logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags),
		logger.Config{
			SlowThreshold:             time.Second, // Slow SQL threshold
			LogLevel:                  logger.Info, // Log level
			IgnoreRecordNotFoundError: false,       // Ignore ErrRecordNotFound error for logger
			ParameterizedQueries:      true,        // Don't include params in the SQL log
			Colorful:                  false,       // Disable color
		},
	)

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{Logger: newLogger})

	if err != nil {
		panic(err)
	}

	db.Raw(sqlTotalCount).Scan(&total)
	db.Raw(sqlPCount).Scan(&alertsPCount)
	db.Raw(sqlAlertClass).Scan(&alertNameCount)
	log.Println("Total:", total)

	log.Println("------------------------------------------------------------")
	alertReport.Total = total
	for _, alert := range alertsPCount {
		switch alert.Severity {
		case "P1":
			alertReport.P1 = alert.Count
		case "P2":
			alertReport.P2 = alert.Count
		case "P3":
			alertReport.P3 = alert.Count
		case "P4":
			alertReport.P4 = alert.Count
		}
		log.Println("serverity:", alert.Severity, "count:", alert.Count)
	}
	log.Println("------------------------------------------------------------")

	log.Println("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
	alertReport.Alerts = alertNameCount
	for _, alert := range alertNameCount {

		log.Println("name:", alert.Name, "count:", alert.Count)
	}
	log.Println("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")

	return alertReport
}
