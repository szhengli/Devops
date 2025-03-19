package main

import (
	"fmt"
	"github.com/go-mysql-org/go-mysql/canal"
	"github.com/go-mysql-org/go-mysql/mysql"
	"github.com/go-mysql-org/go-mysql/replication"
	"log"
	"os"
	"time"
)

type MyEventHandler struct{}

func (h *MyEventHandler) OnRow(e *canal.RowsEvent) error {
	//TODO implement me
	switch e.Action {
	case canal.InsertAction:
		log.Println("Insert event ....", e.Header.LogPos)
		changeTime := int64(e.Header.Timestamp)
		utctime := time.Unix(changeTime, 0)
		localtime := utctime.Local()

		log.Println(e.Table.Schema+"."+e.Table.Name, localtime)
		for _, row := range e.Rows {
			fmt.Printf("Inserted row: %v\n", row)
		}
	case canal.UpdateAction:
		log.Println("UPDATE event:", e.Header.LogPos)
		fmt.Println("||||||||||||||")
		changeTime := int64(e.Header.Timestamp)
		fmt.Println("changetime stamp", changeTime)
		utctime := time.Unix(changeTime, 0)
		fmt.Println("utctime", utctime)
		localtime := utctime.Local()
		fmt.Println("localtime", localtime)
		fmt.Println("||||||||||||||")

		log.Println(e.Table.Schema+"."+e.Table.Name, localtime)
		for _, row := range e.Rows {
			fmt.Printf("Updated row: %v\n", row)
		}
	case canal.DeleteAction:
		log.Println("DELETE event:", e.Header.LogPos)
		changeTime := int64(e.Header.Timestamp)
		utctime := time.Unix(changeTime, 0)
		localtime := utctime.Local()

		log.Println(e.Table.Schema+"."+e.Table.Name, localtime)
		for _, row := range e.Rows {
			fmt.Printf("Deleted row: %v\n", row)
		}
	}
	return nil
}

func (h *MyEventHandler) OnXID(header *replication.EventHeader, nextPos mysql.Position) error {
	//TODO implement me
	return nil
}

func (h *MyEventHandler) OnRotate(header *replication.EventHeader, rotateEvent *replication.RotateEvent) error {
	//TODO implement me
	return nil
}

func (h *MyEventHandler) OnTableChanged(header *replication.EventHeader, schema string, table string) error {
	//TODO implement me
	return nil
}

func (h *MyEventHandler) OnDDL(header *replication.EventHeader, nextPos mysql.Position, queryEvent *replication.QueryEvent) error {
	//TODO implement me
	return nil
}

func (h *MyEventHandler) OnGTID(header *replication.EventHeader, gtidEvent mysql.BinlogGTIDEvent) error {
	//TODO implement me
	return nil
}

func (h *MyEventHandler) OnPosSynced(header *replication.EventHeader, pos mysql.Position, set mysql.GTIDSet, force bool) error {
	//TODO implement me
	return nil
}

func (h *MyEventHandler) OnRowsQueryEvent(e *replication.RowsQueryEvent) error {
	//TODO implement me
	return nil
}

func (h *MyEventHandler) String() string {
	//TODO implement me
	panic("implement string")
}

func (h *MyEventHandler) OnRowEvent(e *canal.RowsEvent) error {

	return nil
}

func main() {
	file, err := os.Open("mysql-bin.000001")
	if err != nil {
		log.Fatal("fail to open the file!")
	}

	defer file.Close()

	c, err := canal.NewCanal(&canal.Config{
		Addr: "192.168.2.207:3306", User: "root", Password: "Zhonglun@2019", ServerID: 100,
		Dump: canal.DumpConfig{
			TableDB: "demo", Tables: []string{"products"},
		},
	})
	if err != nil {
		log.Println("Error initializing canal: %v", err)
	}

	c.SetEventHandler(&MyEventHandler{})

	if err := c.Run(); err != nil {
		log.Fatalf("Error processing binary log file: %v", err)
	}

}
