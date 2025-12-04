@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Django Backend Environment Setup Script (Miniconda)
set CONDA_EXE=d:\miniconda3\Scripts\conda.exe

echo ========================================
echo Django Backend Environment Setup
echo ========================================
echo.

:: Check if conda exists
if not exist "%CONDA_EXE%" (
    echo [ERROR] conda.exe not found at: %CONDA_EXE%
    echo Please verify Miniconda is correctly installed
    pause
    exit /b 1
)

echo [1/5] Conda detected: %CONDA_EXE%
echo.

:: Change to backend directory
cd /d "%~dp0"

echo [2/5] Creating or updating conda environment 'seed_backend'...
"%CONDA_EXE%" env create -f environment.yml 2>nul
if errorlevel 1 (
    echo Environment already exists, updating...
    "%CONDA_EXE%" env update -f environment.yml --prune
)
echo.

echo [3/5] Activating environment and installing dependencies...
call "%CONDA_EXE%" activate seed_backend
if errorlevel 1 (
    echo [ERROR] Failed to activate conda environment
    pause
    exit /b 1
)
echo.

echo [4/5] Running database migrations...
python manage.py makemigrations
python manage.py migrate
echo.

echo [5/5] Setup complete!
echo.
echo ========================================
echo Quick Start Commands
echo ========================================
echo 1. Activate environment:
echo    conda activate seed_backend
echo.
echo 2. Start development server:
echo    python manage.py runserver
echo.
echo 3. Create superuser (optional):
echo    python manage.py createsuperuser
echo.
pause
