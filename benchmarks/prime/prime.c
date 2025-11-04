#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

typedef struct {
    int *data;
    int len;
    int cap;
} IntVec;

bool isPrime(int n) {
    for (int i = 2; i < n; i++) {
        if (n % i == 0) return false;
    }
    return true;
}

IntVec getPrimes(int n) {
    IntVec primes = { NULL, 0, 0 };
    for (int i = 2; i < n; i++) {
        if (isPrime(i)) {
            if (primes.len == primes.cap) {
                int newCap = primes.cap ? primes.cap * 2 : 16;
                int *tmp = realloc(primes.data, newCap * sizeof(int));
                if (!tmp) {
                    free(primes.data);
                    fprintf(stderr, "Allocation failed\n");
                    exit(1);
                }
                primes.data = tmp;
                primes.cap = newCap;
            }
            primes.data[primes.len++] = i;
        }
    }
    return primes;
}

int main(void) {
    IntVec x = getPrimes(25000);
    printf("Go: %d\n", x.len);
    free(x.data);
    return 0;
}
