@echo off
echo ===== BUILDING EXECUTABLES =====
make
echo ================================

echo Starting fib benchmark...
call bat/fib.bat

echo Starting prime benchmark...
call bat/prime.bat

echo Starting multithreading benchmark...
call bat/multithreading.bat

pause