package main

import "fmt"

func main() {
	x := getPrimes(25_000)
	fmt.Println("Go:", len(x))
}

func getPrimes(n int) []int {
	primes := []int{}

	for i := 2; i < n; i++ {
		if isPrime(i) {
			primes = append(primes, i)
		}
	}

	return primes
}

func isPrime(n int) bool {
	for i := 2; i < n; i++ {
		if n%i == 0 {
			return false
		}
	}

	return true
}
