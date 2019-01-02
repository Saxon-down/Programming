package kata

import (
	"math"
)

func FindNb(volume int) int {
	var current float64 = 1.0
	var block float64 = 1.0
	for int(current) < volume {
		block++
		current += math.Pow(block, 3)
	}
	if int(current) > volume {
		return -1
	} else {
		return int(block)
	}
}

func FindNb_BestPractices(m int) int {
	for n := 1 ; m > 0 ; n++ {
	  m -= n*n*n
	  if m == 0 { return n }
	}
	return -1
  }
