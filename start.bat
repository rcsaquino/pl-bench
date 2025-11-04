@echo off
echo ===== CLEANING OLD BUILDS =====
del /q /s build
del /q /s benchmarks\multithreading\rust\target
echo ===============================

echo ===== CREATING NEW BUILDS =====

echo Building go executables ...
go build -o build/fib/go.exe benchmarks/fib/fib.go
go build -o build/prime/go.exe benchmarks/prime/prime.go
go build -o build/multithreading/go.exe benchmarks/multithreading/multithreading.go

echo Building odin executables ...
odin build benchmarks/fib/fib.odin -file -out:build/fib/odin.exe -o:aggressive -vet -strict-style -source-code-locations:obfuscated -disable-assert -no-bounds-check -microarch:native
odin build benchmarks/prime/prime.odin -file -out:build/prime/odin.exe -o:aggressive -vet -strict-style -source-code-locations:obfuscated -disable-assert -no-bounds-check -microarch:native
odin build benchmarks/multithreading/multithreading.odin -file -out:build/multithreading/odin.exe -o:aggressive -vet -strict-style -source-code-locations:obfuscated -disable-assert -no-bounds-check -microarch:native

echo Building rust executables ...
rustc -C opt-level=3 -o build/fib/rust.exe benchmarks/fib/fib.rs
rustc -C opt-level=3 -o build/prime/rust.exe benchmarks/prime/prime.rs
cargo build --manifest-path=benchmarks/multithreading/rust/Cargo.toml --release
if not exist build/multithreading mkdir build/multithreading
move benchmarks\multithreading\rust\target\release\multithreading.exe build\multithreading\rust.exe

echo Building V with GCC executables ...
v -prod -o build/fib/v-gcc.exe -cc gcc benchmarks/fib/fib.v
v -prod -o build/prime/v-gcc.exe -cc gcc benchmarks/prime/prime.v
v -prod -o build/multithreading/v-gcc.exe -cc gcc benchmarks/multithreading/multithreading.v

echo Building V with MSVC executables ...
v -prod -o build/fib/v-msvc.exe -cc msvc benchmarks/fib/fib.v
v -prod -o build/prime/v-msvc.exe -cc msvc benchmarks/prime/prime.v
v -prod -o build/multithreading/v-msvc.exe -cc msvc benchmarks/multithreading/multithreading.v

echo ===============================

echo Starting fib benchmark...
echo ===============================
"build\fib\go.exe"
node benchmarks\fib\fib.js
"build\fib\odin.exe"
"build\fib\rust.exe"
"build\fib\v-gcc.exe"
echo ===============================
echo.
echo ===== FIB BENCHMARK START =====
echo.
hyperfine -w 3 "build\fib\go.exe" "node benchmarks\fib\fib.js" "build\fib\odin.exe" "build\fib\rust.exe" "build\fib\v-gcc.exe" "build\fib\v-msvc.exe"
echo.
echo ====== FIB BENCHMARK END ======
echo.

echo Starting prime benchmark...
echo ===============================
"build\prime\go.exe"
node benchmarks\prime\prime.js
"build\prime\odin.exe"
"build\prime\rust.exe"
"build\prime\v-gcc.exe"
echo ===============================
echo.
echo ===== PRIME BENCHMARK START =====
echo.
hyperfine -w 3 "build\prime\go.exe" "node benchmarks\prime\prime.js" "build\prime\odin.exe" "build\prime\rust.exe" "build\prime\v-gcc.exe" "build\prime\v-msvc.exe"
echo.
echo ===== PRIME BENCHMARK END =====
echo.

echo Starting multithreading benchmark...
echo ===============================
"build\multithreading\go.exe"
"build\multithreading\odin.exe"
"build\multithreading\rust.exe"
"build\multithreading\v-gcc.exe"
echo ===============================
echo.
echo ===== MULTITHREADING BENCHMARK START =====
echo.
hyperfine -w 3 "build\multithreading\go.exe" "build\multithreading\odin.exe" "build\multithreading\rust.exe" "build\multithreading\v-gcc.exe" "build\multithreading\v-msvc.exe"
echo.
echo ===== MULTITHREADING BENCHMARK END =====
echo.

pause