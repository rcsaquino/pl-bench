const std = @import("std");

fn isPrime(n: usize) bool {
    var i: usize = 2;
    while (i < n) : (i += 1) {
        if (n % i == 0) return false;
    }
    return true;
}

fn getPrimes(allocator: std.mem.Allocator, n: usize) ![]usize {
    var primes = try std.ArrayList(usize).initCapacity(allocator, 0);

    var i: usize = 2;
    while (i < n) : (i += 1) {
        if (isPrime(i)) {
            try primes.append(allocator, i);
        }
    }
    return primes.toOwnedSlice(allocator);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const x = try getPrimes(allocator, 25_000);
    defer allocator.free(x);
    std.debug.print("Zig: {d}\n", .{x.len});
}
