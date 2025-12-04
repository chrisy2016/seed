# Mentor Platform Backend - 快速启动脚本
# 使用方法: 
#   方法1: 右键点击 -> 使用PowerShell运行
#   方法2: 在PowerShell中执行: powershell -ExecutionPolicy Bypass -File .\start.ps1
#   方法3: 在PowerShell中执行: .\start.ps1 (需要先设置执行策略)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Mentor Platform Backend 启动脚本" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否在backend目录
if (-not (Test-Path "manage.py")) {
    Write-Host "错误: 请在 backend 目录下运行此脚本！" -ForegroundColor Red
    Write-Host "当前目录: $PWD" -ForegroundColor Yellow
    pause
    exit 1
}

# 检查conda是否存在
$condaPath = "d:\miniconda3\Scripts\conda.exe"
if (-not (Test-Path $condaPath)) {
    Write-Host "错误: 找不到conda，请检查路径: $condaPath" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "✓ 环境检查通过" -ForegroundColor Green
Write-Host "✓ Conda路径: $condaPath" -ForegroundColor Green
Write-Host "✓ 虚拟环境: mentor-backend" -ForegroundColor Green
Write-Host ""

Write-Host "正在启动 Django 开发服务器..." -ForegroundColor Yellow
Write-Host "服务器地址: http://127.0.0.1:8000" -ForegroundColor Cyan
Write-Host "管理后台: http://127.0.0.1:8000/admin" -ForegroundColor Cyan
Write-Host ""
Write-Host "按 Ctrl+C 停止服务器" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 启动Django服务器
& $condaPath run -n mentor-backend python manage.py runserver

Write-Host ""
Write-Host "服务器已停止" -ForegroundColor Red
pause
