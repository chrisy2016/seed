@echo off
chcp 65001 >nul
title Mentor Platform Backend Server

echo ========================================
echo   Mentor Platform Backend 启动脚本
echo ========================================
echo.

REM 检查是否在backend目录
if not exist "manage.py" (
    echo 错误: 请在 backend 目录下运行此脚本！
    echo 当前目录: %CD%
    pause
    exit /b 1
)

REM 检查conda是否存在
if not exist "d:\miniconda3\Scripts\conda.exe" (
    echo 错误: 找不到conda，请检查路径
    pause
    exit /b 1
)

echo ✓ 环境检查通过
echo ✓ Conda路径: d:\miniconda3\Scripts\conda.exe
echo ✓ 虚拟环境: mentor-backend
echo.

echo 正在启动 Django 开发服务器...
echo 服务器地址: http://127.0.0.1:8000
echo 管理后台: http://127.0.0.1:8000/admin
echo.
echo 按 Ctrl+C 停止服务器
echo ========================================
echo.

REM 启动Django服务器
d:\miniconda3\Scripts\conda.exe run -n mentor-backend python manage.py runserver

echo.
echo 服务器已停止
pause
