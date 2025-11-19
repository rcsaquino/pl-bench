#!/usr/bin/env zsh
source "$HOME/.zshrc"
set -e

echo "===== CLEANING OLD BUILDS ====="
rm -rf build
rm -rf benchmarks/multithreading/rust/target
echo "==============================="

echo "===== CREATING NEW BUILDS ====="

# Create build directories
mkdir -p build/fib build/prime build/multithreading

echo "Building Go executables ..."
go build -o build/fib/go benchmarks/fib/fib.go
go build -o build/prime/go benchmarks/prime/prime.go
go build -o build/multithreading/go benchmarks/multithreading/multithreading.go

echo "Building Odin executables ..."
odin build benchmarks/fib/fib.odin -file -out:build/fib/odin -o:aggressive
odin build benchmarks/prime/prime.odin -file -out:build/prime/odin -o:aggressive
odin build benchmarks/multithreading/multithreading.odin -file -out:build/multithreading/odin -o:aggressive

echo "Building Rust executables ..."
rustc -C opt-level=3 -o build/fib/rust benchmarks/fib/fib.rs
rustc -C opt-level=3 -o build/prime/rust benchmarks/prime/prime.rs
cargo build --manifest-path=benchmarks/multithreading/rust/Cargo.toml --release
mv benchmarks/multithreading/rust/target/release/multithreading build/multithreading/rust

echo "Building V executables ..."
v -prod -o build/fib/v benchmarks/fib/fib.v
v -prod -o build/prime/v benchmarks/prime/prime.v
v -prod -o build/multithreading/v benchmarks/multithreading/multithreading.v

echo "Building C executables ..."
gcc -O3 -o build/fib/c benchmarks/fib/fib.c
gcc -O3 -o build/prime/c benchmarks/prime/prime.c

echo "Building Zig executables ..."
zig build-exe benchmarks/fib/fib.zig -O ReleaseFast
mv fib build/fib/zig
zig build-exe benchmarks/prime/prime.zig -O ReleaseFast
mv prime build/prime/zig
zig build-exe benchmarks/multithreading/multithreading.zig -O ReleaseFast
mv multithreading build/multithreading/zig

echo "==============================="

### FIB BENCHMARK ###
echo "Starting fib benchmark..."
echo "=============================="
build/fib/go
# node benchmarks/fib/fib.js
bun run benchmarks/fib/fib.js
build/fib/odin
build/fib/rust
build/fib/v
build/fib/c
build/fib/zig

echo
echo "===== FIB BENCHMARK START ====="
echo

hyperfine -w 3 \
  "build/fib/go" \
  "bun run benchmarks/fib/fib.js" \
  "build/fib/odin" \
  "build/fib/rust" \
  "build/fib/v" \
  "build/fib/c" \
  "build/fib/zig"
# "node benchmarks/fib/fib.js" \
echo
echo "====== FIB BENCHMARK END ======"
echo

### PRIME BENCHMARK ###
echo "Starting prime benchmark..."
echo "=============================="
build/prime/go
# node benchmarks/prime/prime.js
bun run benchmarks/prime/prime.js
build/prime/odin
build/prime/rust
build/prime/v
build/prime/c
build/prime/zig

echo
echo "===== PRIME BENCHMARK START ====="
echo
hyperfine -w 3 \
  "build/prime/go" \
  "bun run benchmarks/prime/prime.js" \
  "build/prime/odin" \
  "build/prime/rust" \
  "build/prime/v" \
  "build/prime/c" \
  "build/prime/zig"
# "node benchmarks/prime/prime.js"
echo
echo "===== PRIME BENCHMARK END ====="
echo

### MULTITHREADING BENCHMARK ###
echo "Starting multithreading benchmark..."
echo "=============================="
build/multithreading/go
build/multithreading/odin
build/multithreading/rust
build/multithreading/v
build/multithreading/zig

echo
echo "===== MULTITHREADING BENCHMARK START ====="
echo
hyperfine -w 3 \
  "build/multithreading/go" \
  "build/multithreading/odin" \
  "build/multithreading/rust" \
  "build/multithreading/v" \
  "build/multithreading/zig"

echo
echo "===== MULTITHREADING BENCHMARK END ====="
echo
