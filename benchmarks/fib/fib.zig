const print = @import("std").debug.print;

pub fn main() void {
    const x: isize = fib(35);
    print("Zig: {}\n", .{x});
}

fn fib(n: isize) isize {
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}
