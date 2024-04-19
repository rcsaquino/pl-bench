package main

import "core:encoding/json"
import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strings"
import "core:thread"

when ODIN_DEBUG {
	tracker: mem.Tracking_Allocator
}

main :: proc() {
	when ODIN_DEBUG {
		fmt.println("Odin Leak Checker Enabled!")
		mem.tracking_allocator_init(&tracker, context.allocator)
		context.allocator = mem.tracking_allocator(&tracker)

		defer {
			total_mem := 0.0
			fmt.printf("\n=== %v allocations not freed: ===\n", len(tracker.allocation_map))
			for _, entry in tracker.allocation_map {
				total_mem += f64(entry.size)
				fmt.printf("LEAK: %v bytes @ %v\n", entry.size, entry.location)
			}
			fmt.printf("\n=== %v incorrect frees: ===\n", len(tracker.bad_free_array))
			for entry in tracker.bad_free_array {
				fmt.printf("BAD FREE: %p @ %v\n", entry.memory, entry.location)
			}
			mem.tracking_allocator_destroy(&tracker)
			fmt.printfln("\nTotal memory leak: %.2f kb\n", total_mem / 1000)
		}
	}


	data, ok := os.read_entire_file("benchmarks/multithreading/db_words/wordle_min.json")
	defer delete(data)
	if !ok {
		panic("Failed to read file")
	}

	possible_answers: []string
	defer {
		for answer in possible_answers {
			delete(answer)
		}
		delete(possible_answers)
	}
	err := json.unmarshal(data, &possible_answers)
	if err != nil {
		panic("Failed to parse json data")
	}

	score_index := make([]int, len(possible_answers))
	defer delete(score_index)
	thread_count := 12
	chunk_size := int(math.ceil(f64(len(possible_answers))) / f64(thread_count))

	threads := make([]^thread.Thread, thread_count)
	defer {
		for t in threads {
			thread.destroy(t)
		}
		delete(threads)
	}

	for chunk in 0 ..< thread_count {
		from := chunk_size * chunk
		to := from + chunk_size
		if (from + chunk_size) > len(possible_answers) {
			to = len(possible_answers)
		}

		t := thread.create_and_start_with_poly_data4(possible_answers, from, to, &score_index, add_scores)
		threads[chunk] = t
	}
	for t in threads {
		thread.join(t)
	}

	index_ref := slice.clone(score_index)
	defer delete(index_ref)
	slice.reverse_sort(score_index)
	output: [6]string
	output[0] = fmt.tprint("Odin: ")
	for i in 0 ..< 5 {
		score := score_index[i]
		output[i + 1] = fmt.tprintf(
			"%v: %v | ",
			possible_answers[find_index(index_ref, score)],
			score,
		)
	}
	result := strings.concatenate(output[:])
	defer delete(result)
	free_all(context.temp_allocator)
	fmt.println(result)
}

print_mutex := b64(false)

did_acquire :: proc(m: ^b64) -> (acquired: bool) {
	res, ok := intrinsics.atomic_compare_exchange_strong(m, false, true)
	return ok && res == false
}

add_scores :: proc(possible_answers: []string, from: int, to: int, score_index: ^[]int) {
	when ODIN_DEBUG {
		context.allocator = mem.tracking_allocator(&tracker)
	}

	for x in from ..< to {
		for y in 0 ..< len(possible_answers) {
			for x_char_index in 0 ..< 5 {
				x_char := possible_answers[x][x_char_index]
				if x_char == possible_answers[y][x_char_index] {
					score_index[y] += 5
				} else if strings.contains_rune(possible_answers[y], rune(x_char)) {
					score_index[y] += 4
				}
			}
		}
	}
}

find_index :: proc(arr: []int, value: int) -> int {
	for v, i in arr {
		if v == value {
			return i
		}
	}
	return -1
}
