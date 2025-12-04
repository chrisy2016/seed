@echo off
REM Django开发服务器启动脚本 - 使用MariaDB

echo ========================================
echo Django开发服务器 (MariaDB)
echo ========================================
echo.
echo 数据库: MariaDB (127.0.0.1:3306/mentor_db)
echo 环境: seed_backend
echo.

REM 切换到脚本所在目录
cd /d "%~dp0"

REM 初始化 Conda（查找 conda.bat 路径）
IF EXIST "%USERPROFILE%\miniconda3\Scripts\activate.bat" (
    call "%USERPROFILE%\miniconda3\Scripts\activate.bat"
) ELSE IF EXIST "%USERPROFILE%\anaconda3\Scripts\activate.bat" (
    call "%USERPROFILE%\anaconda3\Scripts\activate.bat"
) ELSE IF EXIST "D:\miniconda3\Scripts\activate.bat" (
    call "D:\miniconda3\Scripts\activate.bat"
) ELSE IF EXIST "D:\anaconda3\Scripts\activate.bat" (
    call "D:\anaconda3\Scripts\activate.bat"
) ELSE IF EXIST "C:\ProgramData\miniconda3\Scripts\activate.bat" (
    call "C:\ProgramData\miniconda3\Scripts\activate.bat"
) ELSE IF EXIST "C:\ProgramData\anaconda3\Scripts\activate.bat" (
    call "C:\ProgramData\anaconda3\Scripts\activate.bat"
) ELSE (
    echo ✗ 无法找到 Conda 安装路径，请手动激活环境
    echo   运行: conda activate seed_backend
    pause
    exit /b 1
)

REM 激活conda环境
echo 正在激活 conda 环境: seed_backend
call conda activate seed_backend
if errorlevel 1 (
    echo ✗ 环境激活失败，请确保 seed_backend 环境存在
    echo   创建环境: conda env create -f environment.yml
    pause
    exit /b 1
)
echo ✓ 环境激活成功

echo.

REM 检查数据库连接
echo 正在检查数据库连接...
python -c "import MySQLdb; conn = MySQLdb.connect(host='127.0.0.1', user='root', passwd='Ryan@1982', db='mentor_db'); print('✓ 数据库连接正常'); conn.close()" 2>nul
if errorlevel 1 (
    echo ✗ 数据库连接失败，请检查MariaDB是否运行
    echo   可以继续运行服务器，但数据库功能将不可用
    echo.
    choice /C YN /M "是否继续启动服务器"
    if errorlevel 2 (
        exit /b 1
    )
)

echo.
echo 正在启动Django开发服务器...
echo 访问地址: http://127.0.0.1:8000/
echo 管理后台: http://127.0.0.1:8000/admin/
echo.

REM 启动服务器
python manage.py runserver

pause
