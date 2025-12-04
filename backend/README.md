# Mentor Platform - Django Backend

## 项目简介
在线学员学习与进度跟进平台的后端服务，使用Django 5.0构建。

## 技术栈
- Python 3.11
- Django 5.0
- Django REST Framework
- MariaDB/MySQL (生产环境)
- SQLite (开发环境)

## 环境配置

### 1. 创建并激活Conda环境
```bash
conda create -n mentor-backend python=3.11 -y
conda activate mentor-backend
```

### 2. 安装依赖
使用清华源加速安装：
```bash
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 3. 环境变量配置
复制 `.env.example` 为 `.env` 并根据需要修改配置：
```bash
cp .env.example .env
```

### 4. 数据库配置

#### 开发环境（默认使用SQLite）
无需额外配置，直接运行迁移即可。

#### 生产环境（使用MariaDB）
1. 安装并启动MariaDB
2. 创建数据库：
```sql
CREATE DATABASE mentor_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'mentor_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON mentor_db.* TO 'mentor_user'@'localhost';
FLUSH PRIVILEGES;
```
3. 在 `settings.py` 中取消MariaDB配置的注释
4. 在 `.env` 文件中配置数据库连接信息

### 5. 执行数据库迁移
```bash
python manage.py makemigrations
python manage.py migrate
```

### 6. 创建超级用户
```bash
python manage.py createsuperuser
```

### 7. 运行开发服务器
```bash
python manage.py runserver
```

访问 http://127.0.0.1:8000/admin 进入管理后台

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
