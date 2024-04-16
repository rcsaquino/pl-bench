package main

import "core:fmt"

main :: proc() {
	x := get_primes(25_000)
	fmt.println("Odin:", len(x))
}

get_primes :: proc(n: int) -> [dynamic]int {
	primes := [dynamic]int{}

	for i := 2; i < n; i += 1 {
		if is_prime(i) {
			append(&primes, i)
		}
	}

	return primes
}

is_prime :: proc(n: int) -> bool {
	for i := 2; i < n; i += 1 {
		if n % i == 0 {
			return false
		}
	}

	return true
}
