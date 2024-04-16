build-all: build-fib build-prime

clean:
	rm -rf build/*

# FIB
build-fib: build/fib/go.exe build/fib/odin.exe build/fib/rust.exe build/fib/v.exe

build/fib/go.exe: benchmarks/fib/fib.go
	go build -o build/fib/go.exe benchmarks/fib/fib.go

build/fib/odin.exe: benchmarks/fib/fib.odin
	odin build benchmarks/fib/fib.odin -file -out:build/fib/odin.exe -o:speed

build/fib/rust.exe: benchmarks/fib/fib.rs
	rustc -C opt-level=3 -o build/fib/rust.exe benchmarks/fib/fib.rs

build/fib/v.exe: benchmarks/fib/fib.v
	v -prod -o build/fib/v.exe benchmarks/fib/fib.v

# PRIME
build-prime: build/prime/go.exe build/prime/odin.exe build/prime/rust.exe build/prime/v.exe

build/prime/go.exe: benchmarks/prime/prime.go
	go build -o build/prime/go.exe benchmarks/prime/prime.go

build/prime/odin.exe: benchmarks/prime/prime.odin
	odin build benchmarks/prime/prime.odin -file -out:build/prime/odin.exe -o:speed

build/prime/rust.exe: benchmarks/prime/prime.rs
	rustc -C opt-level=3 -o build/prime/rust.exe benchmarks/prime/prime.rs

build/prime/v.exe: benchmarks/prime/prime.v
	v -prod -o build/prime/v.exe benchmarks/prime/prime.v