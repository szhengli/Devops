package main

import (
	"fmt"
	"github.com/go-mysql-org/go-mysql/replication"
	"time"
)

func main() {

	p := replication.NewBinlogParser()

	f := func(e *replication.BinlogEvent) error {

		switch er := e.Event.(type) {
		case *replication.RowsEvent:
			fmt.Println(string(er.Table.Schema) + "." + string(er.Table.Table))

			fmt.Println("logPos:", e.Header.LogPos)
			changeTime := int64(e.Header.Timestamp)
			ctime := time.Unix(changeTime, 0)
			fmt.Println("timestamp: ", ctime)
			fmt.Println("event Type:", e.Header.EventType.String())
			for _, row := range er.Rows {
				fmt.Println("row:", row)
			}

			fmt.Println("||||||||||||||||||||||||||")
			//fmt.Println(er.Table.Flags)

		}

		/**
		if e.Header.EventType.String() == "UpdateRowsEventV2" {
			changeTime := int64(e.Header.Timestamp)
			ctime := time.Unix(changeTime, 0)
			fmt.Println("timestamp: ", ctime)
			fmt.Println("logPos: ", e.Header.LogPos)

			fmt.Println("|||||||||||||||||||||||||||||||||||||||||||")
			e.Dump(os.Stdout)
			fmt.Println("|||||||||||||||||||||||||||||||||||||||||||")
			fmt.Println()
		}

		*/
		return nil
	}

	err := p.ParseFile("mysql-bin.000001", 5461, f)

	if err != nil {
		println(err.Error())
	}

	/**
	logfile, _ := os.Open("mysql-bin.000001")

	err := p.ParseReader(logfile, func(event *replication.BinlogEvent) error {
		event.Dump(os.Stdout)
		return nil
	})
	if err != nil {
		fmt.Println(err)
		return
	}


	*/
}
