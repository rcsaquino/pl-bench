package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"runtime"
	"sort"
	"strings"
	"sync"
)

func main() {
	possible_answers := read("benchmarks/multithreading/db_words/wordle_min.json")
	score_index := make([]int, len(possible_answers))

	thread_count := runtime.NumCPU()
	chunk_size := int(math.Ceil(float64(len(possible_answers)) / float64(thread_count)))

	var wg sync.WaitGroup
	wg.Add(thread_count)
	ch := make(chan []int, thread_count)

	for chunk := 0; chunk < thread_count; chunk++ {
		from := chunk_size * chunk
		to := 0
		if (from + chunk_size) > len(possible_answers) {
			to = len(possible_answers)
		} else {
			to = from + chunk_size
		}

		go func() {
			si := make([]int, len(possible_answers))
			for x := from; x < to; x++ {
				for y := range possible_answers {
					for x_char_index := 0; x_char_index < 5; x_char_index++ {
						x_char := possible_answers[x][x_char_index]
						if x_char == possible_answers[y][x_char_index] {
							si[y] += 5
						} else if strings.Contains(possible_answers[y], string(x_char)) {
							si[y] += 4
						}
					}
				}
			}
			ch <- si
			wg.Done()
		}()
	}
	wg.Wait()
	close(ch)

	for result := range ch {
		for i, v := range result {
			score_index[i] += v
		}
	}

	sorted_scores := make([]int, len(possible_answers))
	copy(sorted_scores, score_index)
	sort.Sort(sort.Reverse(sort.IntSlice(sorted_scores)))

	res := fmt.Sprintf("Go: ")
	for i := 0; i < 5; i++ {
		score := sorted_scores[i]
		res += fmt.Sprintf("%v: %v | ", possible_answers[find_index(score_index, score)], score)
	}
	fmt.Println(res)
}

func read(path string) []string {
	content, err := os.ReadFile(path)
	if err != nil {
		panic(err)
	}
	var data []string
	json.Unmarshal(content, &data)
	return data
}

func find_index(arr []int, value int) int {
	index := -1
	for i, v := range arr {
		if v == value {
			index = i
			break
		}
	}
	return index
}
