@echo off
echo ===== CLEANING OLD EXECUTABLES =====
make clean
echo ====================================
echo ===== BUILDING NEW EXECUTABLES =====
make
echo ====================================

echo Starting fib benchmark...
call bat/fib.bat

echo Starting prime benchmark...
call bat/prime.bat

echo Starting multithreading benchmark...
call bat/multithreading.bat

pause