import json
import os
import math
import runtime

fn main() {
	possible_answers := json.decode([]string, os.read_file('benchmarks/multithreading/db_words/wordle_min.json')!)!

	mut score_index := []int{len: possible_answers.len, init: 0}
	thread_count := runtime.nr_cpus() - 2 // For some reason V runs a lot slower when using all threads. Maybe because of GC?
	chunk_size := int(math.ceil(f64(possible_answers.len) / f64(thread_count)))

	ch := chan []int{}

	for chunk in 0 .. thread_count {
		from := chunk_size * chunk
		to := if (from + chunk_size) > possible_answers.len {
			possible_answers.len
		} else {
			from + chunk_size
		}

		spawn add_scores(possible_answers, from, to, ch)
	}

	for _ in 0 .. thread_count {
		result := <-ch
		for i, v in result {
			score_index[i] += v
		}
	}
	ch.close()

	mut sorted_scores := score_index.clone()
	sorted_scores.sort(a > b)
	mut res := 'V: '
	for i in 0 .. 5 {
		score := sorted_scores[i]
		res += '${possible_answers[score_index.index(score)]}: ${score} | '
	}

	println(res)
}

fn add_scores(possible_answers []string, from int, to int, ch chan []int) {
	mut res := []int{len: possible_answers.len, init: 0}

	for x in from .. to {
		for y in 0 .. possible_answers.len {
			for x_char_index in 0 .. 5 {
				x_char := possible_answers[x][x_char_index]
				if x_char == possible_answers[y][x_char_index] {
					res[y] += 5
				} else if possible_answers[y].contains_u8(x_char) {
					res[y] += 4
				}
			}
		}
	}
	ch <- res
}
