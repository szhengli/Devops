package main

import (
	"fmt"
	"time"
)

func main() {
	// Define the date (2025-02-19)
	layout := "2006-01-02" // The format layout used for parsing
	str := "2025-02-19"

	// Parse the date string into a time.Time object
	t, err := time.Parse(layout, str)
	if err != nil {
		fmt.Println("Error parsing date:", err)
		return
	}

	// Convert to Unix timestamp (seconds since Unix epoch)
	unixTimestamp := t.Unix()

	// Print the Unix timestamp
	fmt.Println("Unix Timestamp:", unixTimestamp)
}
