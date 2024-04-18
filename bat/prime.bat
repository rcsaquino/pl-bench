@echo off
echo ===============================
"build\prime\go.exe"
node benchmarks\prime\prime.js
"build\prime\odin.exe"
"build\prime\rust.exe"
"build\prime\v.exe"
echo ===============================
echo.
echo ===== PRIME BENCHMARK START =====
echo.
hyperfine -w 3 "build\prime\go.exe" "node benchmarks\prime\prime.js" "build\prime\odin.exe" "build\prime\rust.exe" "build\prime\v.exe"
echo.
echo ===== PRIME BENCHMARK END =====
echo.