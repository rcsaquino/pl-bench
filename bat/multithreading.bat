@echo off
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