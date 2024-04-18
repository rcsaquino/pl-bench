package main

import "core:encoding/json"
import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strings"
import "core:thread"

main :: proc() {
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

		t := thread.create(add_scores)
		t.user_args[0] = &possible_answers
		t.user_args[1] = &score_index
		t.user_args[2] = &from
		t.user_args[3] = &to
		thread.start(t)
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
	for i in 1 ..< len(output) {
		score := score_index[i]
		output[i] = fmt.tprintf("%v: %v | ", possible_answers[find_index(index_ref, score)], score)
	}
	result := strings.concatenate(output[:])
	defer delete(result)
	free_all(context.temp_allocator)
	fmt.println(result)
}

add_scores :: proc(t: ^thread.Thread) {
	possible_answers := (^[]string)(t.user_args[0])^
	score_index := (^[]int)(t.user_args[1])^
	from := (^int)(t.user_args[2])^
	to := (^int)(t.user_args[3])^
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
