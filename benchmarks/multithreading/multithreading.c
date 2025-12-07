#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <math.h>
#include <unistd.h>
#include <sys/stat.h>

// Struct to pass arguments to threads
typedef struct {
    char **possible_answers;
    int num_words;
    int from;
    int to;
} ThreadArgs;

// Helper to check if string contains char
int contains_byte(const char *s, char b) {
    for (int i = 0; s[i] != '\0'; i++) {
        if (s[i] == b) {
            return 1;
        }
    }
    return 0;
}

// Thread worker function
void *calculate_scores(void *arguments) {
    ThreadArgs *args = (ThreadArgs *)arguments;
    int *si = (int *)calloc(args->num_words, sizeof(int)); // equivalent to make([]int, len)

    for (int x = args->from; x < args->to; x++) {
        for (int y = 0; y < args->num_words; y++) {
            for (int x_char_index = 0; x_char_index < 5; x_char_index++) {
                char x_char = args->possible_answers[x][x_char_index];
                if (x_char == args->possible_answers[y][x_char_index]) {
                    si[y] += 5;
                } else if (contains_byte(args->possible_answers[y], x_char)) {
                    si[y] += 4;
                }
            }
        }
    }
    return (void *)si;
}

// Helper to read and parse JSON string array
char **read_words(const char *path, int *count) {
    FILE *f = fopen(path, "rb");
    if (!f) {
        perror("Error opening file");
        exit(1);
    }

    fseek(f, 0, SEEK_END);
    long length = ftell(f);
    fseek(f, 0, SEEK_SET);

    char *content = malloc(length + 1);
    fread(content, 1, length, f);
    content[length] = '\0';
    fclose(f);

    // First pass: count words to allocate array
    int words = 0;
    for (int i = 0; i < length; i++) {
        if (content[i] == '"' && (i == 0 || content[i-1] != '\\')) {
            words++;
        }
    }
    words /= 2; // Two quotes per word
    *count = words;

    char **data = malloc(words * sizeof(char *));
    
    // Second pass: extract words
    int w_idx = 0;
    int in_quote = 0;
    int start = 0;
    
    for (int i = 0; i < length; i++) {
        if (content[i] == '"') {
            if (!in_quote) {
                in_quote = 1;
                start = i + 1;
            } else {
                in_quote = 0;
                int word_len = i - start;
                data[w_idx] = malloc(word_len + 1);
                strncpy(data[w_idx], content + start, word_len);
                data[w_idx][word_len] = '\0';
                w_idx++;
            }
        }
    }
    
    free(content);
    return data;
}

// Compare function for qsort (Reverse order)
int compare_desc(const void *a, const void *b) {
    return (*(int *)b - *(int *)a);
}

// Find index of value in array
int find_index(int *arr, int size, int value) {
    for (int i = 0; i < size; i++) {
        if (arr[i] == value) {
            return i;
        }
    }
    return -1;
}

int main() {
    int num_words;
    char **possible_answers = read_words("benchmarks/multithreading/db_words/wordle_min.json", &num_words);
    
    int *score_index = (int *)calloc(num_words, sizeof(int));
    
    int thread_count = sysconf(_SC_NPROCESSORS_ONLN);
    int chunk_size = (int)ceil((double)num_words / (double)thread_count);

    pthread_t *threads = malloc(thread_count * sizeof(pthread_t));
    ThreadArgs *t_args = malloc(thread_count * sizeof(ThreadArgs));

    // Create threads
    for (int chunk = 0; chunk < thread_count; chunk++) {
        int from = chunk_size * chunk;
        int to = from + chunk_size;
        if (to > num_words) {
            to = num_words;
        }

        t_args[chunk].possible_answers = possible_answers;
        t_args[chunk].num_words = num_words;
        t_args[chunk].from = from;
        t_args[chunk].to = to;

        if (pthread_create(&threads[chunk], NULL, calculate_scores, &t_args[chunk]) != 0) {
            perror("Failed to create thread");
            return 1;
        }
    }

    // Join threads and aggregate results
    for (int i = 0; i < thread_count; i++) {
        void *ret;
        pthread_join(threads[i], &ret);
        int *partial_result = (int *)ret;
        
        for (int j = 0; j < num_words; j++) {
            score_index[j] += partial_result[j];
        }
        free(partial_result);
    }

    // Sort scores
    int *sorted_scores = malloc(num_words * sizeof(int));
    memcpy(sorted_scores, score_index, num_words * sizeof(int));
    qsort(sorted_scores, num_words, sizeof(int), compare_desc);

    // Print results
    printf("C: ");
    for (int i = 0; i < 5; i++) {
        int score = sorted_scores[i];
        int original_index = find_index(score_index, num_words, score);
        printf("%s: %d | ", possible_answers[original_index], score);
    }
    printf("\n");

    // Cleanup
    for(int i = 0; i < num_words; i++) free(possible_answers[i]);
    free(possible_answers);
    free(score_index);
    free(sorted_scores);
    free(threads);
    free(t_args);

    return 0;
}