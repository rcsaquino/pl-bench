fn main() {
	x := fib(35)
	println('V: ${x}')
}

fn fib(n int) int {
	if n <= 1 {
		return n
	}
	return fib(n - 1) + fib(n - 2)
}
