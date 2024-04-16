fn main() {
    let primes = get_primes(25_000);
    println!("Rust: {:?}", primes.len());
}

fn get_primes(n: i32) -> Vec<i32> {
    let mut primes = Vec::new();
    for i in 2..n {
        if is_prime(i) {
            primes.push(i);
        }
    }
    return primes;
}

fn is_prime(n: i32) -> bool {
    for i in 2..n {
        if n % i == 0 {
            return false;
        }
    }
    return true;
}
