// Import the Zig standard library
const std = @import("std");

// -----------------------------
// Function: containsByte
// Checks if a given byte `b` exists anywhere inside the byte array `s`.
// Think of it like checking if a letter is inside a word.
// Returns true if found, false otherwise.
// -----------------------------
fn containsByte(s: []const u8, b: u8) bool {
    for (s) |ch| {
        if (ch == b) return true;
    }
    return false;
}

// -----------------------------
// Function: worker
// Compares words within a given slice of the list `possible`.
// Each thread runs this function on its assigned "chunk" of words (from → to).
// For each word `xword`, it compares against every other `yword`.
// The scoring rules are similar to "Wordle":
//   - +5 if a letter matches in the same position
//   - +4 if the letter exists elsewhere in the word
// Results are stored in the shared score array `si`.
// -----------------------------
fn worker(
    possible: []const []const u8, // All possible words
    from: usize, // Starting index for this thread
    to: usize, // Ending index for this thread
    si: []i32, // Output scores (per thread)
) void {
    var x: usize = from;
    while (x < to) : (x += 1) {
        const xword = possible[x];

        var y: usize = 0;
        while (y < possible.len) : (y += 1) {
            const yword = possible[y];

            var idx: usize = 0;
            // Compare each letter (assuming 5-letter words)
            while (idx < 5) : (idx += 1) {
                const xc = xword[idx];
                if (xc == yword[idx]) {
                    // Exact letter match in position
                    si[y] += 5;
                } else if (containsByte(yword, xc)) {
                    // Letter exists elsewhere in the word
                    si[y] += 4;
                }
            }
        }
    }
}

// -----------------------------
// Function: findIndex
// Returns the index of the first occurrence of `value` in the integer array `arr`.
// If not found, returns null (Zig's way of saying “no result”).
// -----------------------------
fn findIndex(arr: []const i32, value: i32) ?usize {
    for (arr, 0..) |v, i| {
        if (v == value) return i;
    }
    return null;
}

// -----------------------------
// Main entry point
// -----------------------------
pub fn main() !void {
    // -----------------------------
    // SETUP MEMORY ALLOCATOR
    // -----------------------------
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    // -----------------------------
    // READ JSON WORD LIST FROM FILE
    // -----------------------------
    const path: []const u8 = "benchmarks/multithreading/db_words/wordle_min.json";
    const max_bytes: usize = 64 * 1024 * 1024; // Limit read size to 64 MB
    const content = try std.fs.cwd().readFileAlloc(allocator, path, max_bytes);
    defer allocator.free(content);

    // -----------------------------
    // PARSE JSON (expects an array of strings)
    // -----------------------------
    const parsed = try std.json.parseFromSlice([][]const u8, allocator, content, .{});
    defer parsed.deinit();
    const possible_answers = parsed.value; // Array of possible words

    // -----------------------------
    // PREPARE SCORE ARRAY (initialized to zero)
    // -----------------------------
    const n = possible_answers.len;
    var score_index = try allocator.alloc(i32, n);
    defer allocator.free(score_index);

    // Initialize all scores to zero
    var zi: usize = 0;
    while (zi < score_index.len) : (zi += 1) {
        score_index[zi] = 0;
    }
    // (Alternative: @memset(score_index, 0))

    // -----------------------------
    // DETERMINE THREAD COUNT AND CHUNKS
    // -----------------------------
    const thread_count = try std.Thread.getCpuCount();
    const chunks = if (thread_count == 0) 1 else thread_count;
    const chunk_size: usize = (n + chunks - 1) / chunks;

    // -----------------------------
    // SPAWN WORKER THREADS
    // Each worker compares a portion of the word list and writes scores
    // to its own result array.
    // -----------------------------
    var spawned: usize = 0;

    var handles = try allocator.alloc(std.Thread, chunks);
    defer allocator.free(handles);

    var results = try allocator.alloc([]i32, chunks);
    defer {
        // Free per-thread result arrays after use
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

        // Allocate zeroed score array for this thread
        const si = try allocator.alloc(i32, n);
        var ii: usize = 0;
        while (ii < si.len) : (ii += 1) {
            si[ii] = 0;
        }
        results[spawned] = si;

        // Start thread: each worker gets its own portion and buffer
        handles[spawned] = try std.Thread.spawn(.{}, worker, .{ possible_answers, from, to, si });
        spawned += 1;
    }

    // -----------------------------
    // WAIT FOR ALL THREADS TO FINISH
    // -----------------------------
    var j: usize = 0;
    while (j < spawned) : (j += 1) {
        handles[j].join();
    }

    // -----------------------------
    // AGGREGATE ALL THREAD RESULTS
    // Combine all per-thread score arrays into the main score_index array.
    // -----------------------------
    var r: usize = 0;
    while (r < spawned) : (r += 1) {
        const si = results[r];
        var i: usize = 0;
        while (i < n) : (i += 1) {
            score_index[i] += si[i];
        }
    }

    // -----------------------------
    // SORT SCORES (highest first)
    // -----------------------------
    const sorted_scores = try allocator.dupe(i32, score_index);
    defer allocator.free(sorted_scores);
    std.mem.sort(i32, sorted_scores, {}, comptime std.sort.desc(i32));

    // -----------------------------
    // DISPLAY TOP 5 RESULTS
    // Prints the top 5 words with the highest total scores.
    // -----------------------------
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

    // Print the output string to the console
    std.debug.print("{s}\n", .{out.items});
}
