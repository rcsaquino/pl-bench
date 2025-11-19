const std = @import("std");

fn containsByte(s: []const u8, b: u8) bool {
    for (s) |ch| {
        if (ch == b) return true;
    }
    return false;
}

fn worker(
    possible: []const []const u8,
    from: usize,
    to: usize,
    si: []i32,
) void {
    var x: usize = from;
    while (x < to) : (x += 1) {
        const xword = possible[x];

        var y: usize = 0;
        while (y < possible.len) : (y += 1) {
            const yword = possible[y];

            var idx: usize = 0;
            while (idx < 5) : (idx += 1) {
                const xc = xword[idx];
                if (xc == yword[idx]) {
                    si[y] += 5;
                } else if (containsByte(yword, xc)) {
                    si[y] += 4;
                }
            }
        }
    }
}

fn findIndex(arr: []const i32, value: i32) ?usize {
    for (arr, 0..) |v, i| {
        if (v == value) return i;
    }
    return null;
}

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const path: []const u8 = "benchmarks/multithreading/db_words/wordle_min.json";
    const max_bytes: usize = 64 * 1024 * 1024; // Limit read size to 64 MB
    const content = try std.fs.cwd().readFileAlloc(allocator, path, max_bytes);
    defer allocator.free(content);

    const parsed = try std.json.parseFromSlice([][]const u8, allocator, content, .{});
    defer parsed.deinit();
    const possible_answers = parsed.value;

    const n = possible_answers.len;
    var score_index = try allocator.alloc(i32, n);
    defer allocator.free(score_index);

    var zi: usize = 0;
    while (zi < score_index.len) : (zi += 1) {
        score_index[zi] = 0;
    }

    const thread_count = try std.Thread.getCpuCount();
    const chunks = if (thread_count == 0) 1 else thread_count;
    const chunk_size: usize = (n + chunks - 1) / chunks;

    var spawned: usize = 0;

    var handles = try allocator.alloc(std.Thread, chunks);
    defer allocator.free(handles);

    var results = try allocator.alloc([]i32, chunks);
    defer {
        var i: usize = 0;
        while (i < spawned) : (i += 1) {
            allocator.free(results[i]);
        }
        allocator.free(results);
    }

    var t: usize = 0;
    while (t < chunks) : (t += 1) {
        const from = chunk_size * t;
        if (from >= n) break;
        const to = @min(from + chunk_size, n);

        const si = try allocator.alloc(i32, n);
        var ii: usize = 0;
        while (ii < si.len) : (ii += 1) {
            si[ii] = 0;
        }
        results[spawned] = si;

        handles[spawned] = try std.Thread.spawn(.{}, worker, .{ possible_answers, from, to, si });
        spawned += 1;
    }

    var j: usize = 0;
    while (j < spawned) : (j += 1) {
        handles[j].join();
    }

    var r: usize = 0;
    while (r < spawned) : (r += 1) {
        const si = results[r];
        var i: usize = 0;
        while (i < n) : (i += 1) {
            score_index[i] += si[i];
        }
    }

    const sorted_scores = try allocator.dupe(i32, score_index);
    defer allocator.free(sorted_scores);
    std.mem.sort(i32, sorted_scores, {}, comptime std.sort.desc(i32));

    var out = try std.ArrayList(u8).initCapacity(allocator, 128);
    defer out.deinit(allocator);
    const w = out.writer(allocator);

    try w.print("Zig: ", .{});
    var k: usize = 0;
    var printed: usize = 0;
    while (k < sorted_scores.len and printed < 5) : (k += 1) {
        const score = sorted_scores[k];
        const idx = findIndex(score_index, score) orelse continue;
        try w.print("{s}: {d} | ", .{ possible_answers[idx], score });
        printed += 1;
    }

    std.debug.print("{s}\n", .{out.items});
}
