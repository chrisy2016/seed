# Django Backend环境设置脚本 (Miniconda)
# 使用方法: .\setup_env.ps1

$ErrorActionPreference = "Stop"
$CONDA_EXE = "d:\miniconda3\Scripts\conda.exe"

Write-Host "=== Django Backend 环境设置 ===" -ForegroundColor Cyan
Write-Host ""

# 检查conda是否存在
if (-not (Test-Path $CONDA_EXE)) {
    Write-Host "错误: 未找到 conda.exe 在 $CONDA_EXE" -ForegroundColor Red
    Write-Host "请确认 Miniconda 已正确安装" -ForegroundColor Yellow
    exit 1
}

Write-Host "步骤 1/5: 检测到 conda: $CONDA_EXE" -ForegroundColor Green

# 进入backend目录
$BACKEND_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $BACKEND_DIR

Write-Host "步骤 2/5: 创建或更新 conda 环境 'seed_backend'..." -ForegroundColor Yellow
& $CONDA_EXE env create -f environment.yml 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "环境已存在，尝试更新..." -ForegroundColor Yellow
    & $CONDA_EXE env update -f environment.yml --prune
}

Write-Host "步骤 3/5: 激活环境并安装依赖..." -ForegroundColor Yellow
# 初始化conda for PowerShell
& $CONDA_EXE shell.powershell hook | Out-String | Invoke-Expression

# 激活环境
conda activate seed_backend

if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 无法激活 conda 环境" -ForegroundColor Red
    exit 1
}

Write-Host "步骤 4/5: 执行数据库迁移..." -ForegroundColor Yellow
python manage.py makemigrations
python manage.py migrate

Write-Host "步骤 5/5: 环境设置完成！" -ForegroundColor Green
Write-Host ""
Write-Host "=== 快速启动命令 ===" -ForegroundColor Cyan
Write-Host "1. 激活环境:"
Write-Host "   conda activate seed_backend" -ForegroundColor White
Write-Host ""
Write-Host "2. 启动开发服务器:"
Write-Host "   python manage.py runserver" -ForegroundColor White
Write-Host ""
Write-Host "3. 创建超级用户 (可选):"
Write-Host "   python manage.py createsuperuser" -ForegroundColor White
Write-Host ""
