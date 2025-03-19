package main

import (
	"fmt"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"log"
	"os"
	"time"
)

type Employee struct {
	Id   int
	Name string
}

func (e *Employee) BeforeCreate(tx *gorm.DB) (err error) {
	fmt.Println(e.Name)
	return nil
}

type Roles []string

func main() {

	newLogger := logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags),
		logger.Config{
			SlowThreshold:             time.Second,  // Slow SQL threshold
			LogLevel:                  logger.Error, // Log level
			IgnoreRecordNotFoundError: false,        // Ignore ErrRecordNotFound error for logger
			ParameterizedQueries:      true,         // Don't include params in the SQL log
			Colorful:                  false,        // Disable color
		},
	)

	dsn := "root:Zhonglun@2019@tcp(192.168.2.207:3306)/demo?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{Logger: newLogger})

	if err != nil {
		panic(err)
	}
	//var employee Employee

	//	var age int

	//db.Raw("SELECT * FROM employees WHERE id = ?", 10).Scan(&employee)

	Employees := []Employee{
		{Name: "Donghe2"},
		{Name: "xinlei2"},
		{Name: "zhugang2"},
	}
	re := db.Create(Employees)

	fmt.Println(re.RowsAffected)
	//db.Raw("UPDATE employees set name = ?  where id = ?", "apple", 10).Scan(&employee)

	//db.Create(&Employee{Name: "cody"})
	//err = db.Where("id = ?", 1).First(&employee).Error

	//log.Println(employee.Name)

}
