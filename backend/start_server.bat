@echo off
REM Django开发服务器启动脚本 - 使用MariaDB

echo ========================================
echo Django开发服务器 (MariaDB)
echo ========================================
echo.
echo 数据库: MariaDB (127.0.0.1:3306/mentor_db)
echo 环境: seed_backend
echo.

REM 激活conda环境
call conda activate seed_backend

REM 检查数据库连接
echo 正在检查数据库连接...
python -c "import MySQLdb; conn = MySQLdb.connect(host='127.0.0.1', user='root', passwd='Ryan@1982', db='mentor_db'); print('✓ 数据库连接正常'); conn.close()" 2>nul
if errorlevel 1 (
    echo ✗ 数据库连接失败，请检查MariaDB是否运行
    pause
    exit /b 1
)

echo.
echo 正在启动Django开发服务器...
echo.

REM 启动服务器
python manage.py runserver

pause
