package main

import "fmt"

func main() {
	x := fib(35)
	fmt.Println("Go:", x)
}

func fib(n int) int {
	if n <= 1 {
		return n
	}

	return fib(n-1) + fib(n-2)
}
