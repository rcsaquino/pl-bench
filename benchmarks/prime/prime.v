fn main() {
	x := get_primes(25_000)
	println('V: ${x.len}')
}

fn get_primes(n int) []int {
	mut primes := []int{}

	for i := 2; i < n; i++ {
		if is_prime(i) {
			primes << i
		}
	}

	return primes
}

fn is_prime(n int) bool {
	for i := 2; i < n; i++ {
		if n % i == 0 {
			return false
		}
	}

	return true
}
