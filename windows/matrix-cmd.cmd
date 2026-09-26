@echo off
rem Matrix look for cmd.exe: a burst of digital rain, then a green prompt.
rem The "Matrix CMD" terminal profile runs this file.
title Matrix
set "MATRIX_DIR=%~dp0"
if not defined MATRIX_HELLO_NAME set "MATRIX_HELLO_NAME=Neo"
if not defined MATRIX_SPLASH set "MATRIX_SPLASH=2"
set /p MATRIX_PY=<"%MATRIX_DIR%python-path.txt"
if not "%MATRIX_SPLASH%"=="0" "%MATRIX_PY%" "%MATRIX_DIR%matrix_hello.py" --splash %MATRIX_SPLASH%
cls
rem cmd has no escape sequence for ESC, so borrow one from the prompt command.
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
echo %ESC%[1;92mWake up, %MATRIX_HELLO_NAME%...%ESC%[0;32m The Matrix has you.%ESC%[0m
echo.
prompt $E[1;92m%MATRIX_HELLO_NAME%@matrix$E[0;32m $P$E[1;97m$G$E[0m$S
