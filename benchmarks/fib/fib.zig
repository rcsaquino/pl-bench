const print = @import("std").debug.print;

pub fn main() void {
    const x: i32 = fib(35);
    print("Zig: {}\n", .{x});
}

fn fib(n: i32) i32 {
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}
