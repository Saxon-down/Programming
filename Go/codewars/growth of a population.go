package main

import (
	"fmt"
)

func NbYear(currentPop int, percent float64, annualAdd int, target int) int {
	var year int
	for year = 0; currentPop < target; year++ {
		currentPop = int(((100+percent)*float64(currentPop))/100) + annualAdd
	}
	return year
}

func main() {
	fmt.Println(NbYear(1500, 5, 100, 5000))            // 15
	fmt.Println(NbYear(1500000, 2.5, 10000, 2000000))  // 10
	fmt.Println(NbYear(1500000, 0.25, 1000, 2000000))  // 94
	fmt.Println(NbYear(1500000, 0.25, -1000, 2000000)) // 151
}
