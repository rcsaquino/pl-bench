package main

import "core:fmt"

main :: proc() {
	x := fib(35)
	fmt.println("Odin:", x)
}

fib :: proc(n: int) -> int {
	if n <= 1 {
		return n
	}

	return fib(n - 1) + fib(n - 2)
}
