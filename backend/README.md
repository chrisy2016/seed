# Mentor Platform - Django Backend

## 项目简介
在线学员学习与进度跟进平台的后端服务，使用Django 5.0构建。

## ⚠️ 数据库配置变更
**当前数据库: MariaDB** (已从SQLite迁移完成)
- 主机: 127.0.0.1:3306
- 数据库: mentor_db
- 详情请查看: [MIGRATION_COMPLETE.md](MIGRATION_COMPLETE.md)

## 技术栈
- Python 3.11
- Django 5.0
- Django REST Framework
- **MariaDB** (当前使用)
- SQLite (已替换)

## 环境配置

### 方法一：快速自动设置（推荐）

**直接双击运行批处理脚本**（无需配置PowerShell）：

```
backend\setup_env.bat
```

或在命令行中：

```cmd
cd backend
setup_env.bat
```

该脚本会自动完成：
- ✅ 创建 conda 环境 `seed_backend` (Python 3.11)
- ✅ 安装所有依赖项
- ✅ 执行数据库迁移

### 方法二：手动设置

#### 1. 创建并激活Conda环境

```cmd
:: 使用 environment.yml 创建环境
d:\miniconda3\Scripts\conda.exe env create -f environment.yml

:: 激活环境
conda activate seed_backend
```

或手动创建：

```cmd
d:\miniconda3\Scripts\conda.exe create -n seed_backend python=3.11 -y
conda activate seed_backend
```

#### 2. 安装依赖

```cmd
pip install -r requirements.txt
```

如需使用清华源加速：
```cmd
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 3. 环境变量配置
复制 `.env.example` 为 `.env` 并根据需要修改配置：
```bash
cp .env.example .env
```

### 4. 数据库配置

#### 当前配置（MariaDB）✅
项目已配置使用MariaDB数据库：
- 主机: 127.0.0.1
- 端口: 3306
- 数据库: mentor_db
- 用户: root

数据库已创建并完成迁移。如需重新设置，可以运行：
```cmd
python create_db.py
python manage.py migrate
```

#### 快速启动
双击运行 `start_server.bat` 即可启动开发服务器（会自动检查数据库连接）

#### 数据库管理
- 查看迁移完成报告: [MIGRATION_COMPLETE.md](MIGRATION_COMPLETE.md)
- 查看详细迁移指南: [MARIADB_MIGRATION.md](MARIADB_MIGRATION.md)

### 5. 执行数据库迁移（手动设置时需要）

```cmd
python manage.py makemigrations
python manage.py migrate
```

### 6. 创建超级用户

```cmd
python manage.py createsuperuser
```

### 7. 运行开发服务器

```cmd
python manage.py runserver
```

访问 http://127.0.0.1:8000/admin 进入管理后台

## 常见问题

### conda 命令未找到
1. 确保 Miniconda 已正确安装在 `d:\miniconda3`
2. 或将 `d:\miniconda3\Scripts` 添加到系统 PATH 环境变量

### mysqlclient 安装失败
在 Windows 上，如果遇到 `mysqlclient` 编译错误：
1. 使用开发环境的 SQLite（默认配置）
2. 或安装预编译的 wheel：
```cmd
pip install mysqlclient --only-binary :all:
```

### 端口被占用
如果 8000 端口被占用，可以指定其他端口：
```cmd
python manage.py runserver 8001
```

## 项目结构
```
backend/
├── manage.py                  # Django管理脚本
├── requirements.txt           # Python依赖
├── .env.example              # 环境变量模板
├── mentor_platform/          # 项目配置目录
│   ├── settings.py           # 项目设置
│   ├── urls.py               # URL路由
│   └── wsgi.py               # WSGI配置
├── users/                    # 用户管理应用
├── courses/                  # 课程管理应用
├── progress/                 # 学习进度应用
└── authentication/           # 认证授权应用
```

## 核心应用模块

### users - 用户管理
管理学员、教师、管理员等用户信息

### courses - 课程管理
课程创建、编辑、分类等功能

### progress - 学习进度跟踪
记录和跟踪学员的学习进度

### authentication - 认证授权
用户登录、注册、权限管理

## API文档
启动服务后访问：
- REST API 浏览界面: http://127.0.0.1:8000/api/
- Admin后台: http://127.0.0.1:8000/admin/

## 使用Conda运行命令
如果未激活conda环境，可以使用以下方式运行命令：
```bash
# Windows
d:\miniconda3\Scripts\conda.exe run -n mentor-backend python manage.py [command]

# Linux/Mac
conda run -n mentor-backend python manage.py [command]
```

## 开发注意事项
1. 开发环境已配置CORS允许所有源，生产环境需要限制
2. SECRET_KEY在生产环境必须更改
3. DEBUG在生产环境必须设置为False
4. 时区已设置为Asia/Shanghai，语言为zh-hans

## 下一步开发
1. 定义各应用的数据模型（models.py）
2. 创建序列化器（serializers.py）
3. 实现视图和API端点（views.py）
4. 配置URL路由
5. 编写单元测试
