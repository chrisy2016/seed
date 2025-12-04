@echo off
REM MariaDB数据库设置脚本
REM 调用PowerShell脚本进行设置

echo 启动MariaDB数据库设置...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0setup_mariadb.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo 设置过程中出现错误
    pause
    exit /b %ERRORLEVEL%
)

echo.
pause
