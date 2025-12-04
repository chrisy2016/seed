# MariaDB数据库设置脚本
# 此脚本将创建数据库并运行Django迁移

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "MariaDB数据库设置向导" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否安装了mysql命令行工具
Write-Host "步骤 1: 检查MySQL/MariaDB客户端..." -ForegroundColor Yellow
$mysqlPath = Get-Command mysql -ErrorAction SilentlyContinue
if (-not $mysqlPath) {
    Write-Host "警告: 未找到mysql命令行工具" -ForegroundColor Red
    Write-Host "请确保MariaDB已安装并将bin目录添加到PATH环境变量" -ForegroundColor Red
    Write-Host "或手动运行: mysql -u root -p -h 127.0.0.1 < create_database.sql" -ForegroundColor Yellow
    $skipDbCreation = $true
} else {
    Write-Host "✓ MySQL/MariaDB客户端已找到" -ForegroundColor Green
    $skipDbCreation = $false
}

# 创建数据库
if (-not $skipDbCreation) {
    Write-Host ""
    Write-Host "步骤 2: 创建数据库..." -ForegroundColor Yellow
    Write-Host "正在连接到MariaDB (127.0.0.1)..." -ForegroundColor Gray
    Write-Host "密码: Ryan@1982" -ForegroundColor Gray
    
    # 使用SQL脚本创建数据库
    $env:MYSQL_PWD = "Ryan@1982"
    $result = mysql -u root -h 127.0.0.1 -e "CREATE DATABASE IF NOT EXISTS mentor_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>&1
    Remove-Item Env:\MYSQL_PWD
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 数据库 'mentor_db' 创建成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 数据库创建失败: $result" -ForegroundColor Red
        Write-Host "请手动创建数据库或检查连接信息" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "步骤 2: 跳过数据库创建" -ForegroundColor Yellow
    Write-Host "请手动创建数据库 'mentor_db'" -ForegroundColor Yellow
}

# 检查Python环境
Write-Host ""
Write-Host "步骤 3: 检查Python环境..." -ForegroundColor Yellow
$pythonPath = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonPath) {
    Write-Host "✗ 未找到Python" -ForegroundColor Red
    Write-Host "请安装Python并添加到PATH" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Python已找到: $($pythonPath.Source)" -ForegroundColor Green

# 安装依赖
Write-Host ""
Write-Host "步骤 4: 安装Python依赖..." -ForegroundColor Yellow
Write-Host "正在安装 requirements.txt 中的包..." -ForegroundColor Gray
pip install -r requirements.txt
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ 依赖安装成功" -ForegroundColor Green
} else {
    Write-Host "✗ 依赖安装失败" -ForegroundColor Red
    Write-Host "请手动运行: pip install -r requirements.txt" -ForegroundColor Yellow
}

# 运行数据库迁移
Write-Host ""
Write-Host "步骤 5: 运行数据库迁移..." -ForegroundColor Yellow

Write-Host "正在创建迁移文件..." -ForegroundColor Gray
python manage.py makemigrations
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 创建迁移文件失败" -ForegroundColor Red
    exit 1
}

Write-Host "正在应用迁移..." -ForegroundColor Gray
python manage.py migrate
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ 数据库迁移成功完成" -ForegroundColor Green
} else {
    Write-Host "✗ 数据库迁移失败" -ForegroundColor Red
    Write-Host "请检查数据库连接和配置" -ForegroundColor Yellow
    exit 1
}

# 完成
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "数据库设置完成！" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步:" -ForegroundColor Yellow
Write-Host "1. 创建超级用户: python manage.py createsuperuser" -ForegroundColor White
Write-Host "2. 启动开发服务器: python manage.py runserver" -ForegroundColor White
Write-Host ""
Write-Host "数据库信息:" -ForegroundColor Yellow
Write-Host "  主机: 127.0.0.1" -ForegroundColor White
Write-Host "  端口: 3306" -ForegroundColor White
Write-Host "  数据库: mentor_db" -ForegroundColor White
Write-Host "  用户名: root" -ForegroundColor White
Write-Host ""
