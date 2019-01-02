package kata

func BouncingBall(h, bounce, window float64) int {
  if (h <= window) || (bounce >= 1) || (bounce <= 0) || (window < 0) {
    // one of the parameters is out of bounds
    return -1
  } else {
    var numBounce int = 1
    for h > window {
      h = h * bounce
      if h > window {
        numBounce = numBounce + 2
      }
    }
    return numBounce
  }
}


func BouncingBall_BestPractices(h, bounce, window float64) int {
    if h < 0 || bounce <= 0 || 1 <= bounce || h < window {
        return -1
    }
    
    var count int = -1
    for ; h > window; h *= bounce {
        count += 2 
    }
    
    return count
}