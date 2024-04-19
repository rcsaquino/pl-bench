@echo off
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