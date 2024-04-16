@echo off
echo ===============================
"build\fib\go.exe"
node benchmarks\fib\fib.js
"build\fib\odin.exe"
"build\fib\rust.exe"
"build\fib\v.exe"
echo ===============================
echo.
echo ===== FIB BENCHMARK START =====
echo.
hyperfine -w 3 "build\fib\go.exe" "node benchmarks\fib\fib.js" "build\fib\odin.exe" "build\fib\rust.exe" "build\fib\v.exe"
echo.
echo ====== FIB BENCHMARK END ======
echo.