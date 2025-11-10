fn main() {
    let x = fib(35);
    println!("Rust: {}", x);
}

fn fib(n: isize) -> isize {
    if n <= 1 {
        return n;
    }

    return fib(n - 1) + fib(n - 2);
}
