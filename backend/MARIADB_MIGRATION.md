# MariaDB数据库迁移指南

## 已完成的修改

### 1. 数据库配置修改
- 已将 `backend/mentor_platform/settings.py` 中的数据库配置从 SQLite 改为 MariaDB
- 数据库连接信息：
  - 主机: 127.0.0.1
  - 端口: 3306
  - 数据库名: mentor_db
  - 用户名: root
  - 密码: Ryan@1982

### 2. 创建的文件
- `.env`: 环境变量配置文件（包含数据库密码）
- `create_database.sql`: MariaDB数据库创建脚本

### 3. 依赖包
- `mysqlclient==2.2.7` 已在 requirements.txt 中
- `python-dotenv==1.2.1` 已在 requirements.txt 中

## 迁移步骤

### 步骤1: 确保MariaDB服务正在运行
确保你的本地MariaDB服务已启动并可访问。

### 步骤2: 创建数据库
使用以下命令连接到MariaDB并创建数据库：

```bash
# 方法1: 使用命令行
mysql -u root -p -h 127.0.0.1
# 输入密码: Ryan@1982

# 然后执行：
CREATE DATABASE IF NOT EXISTS mentor_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
exit;
```

或者使用提供的SQL脚本：

```bash
mysql -u root -p -h 127.0.0.1 < create_database.sql
```

### 步骤3: 安装Python依赖（如果尚未安装）
```bash
cd backend
pip install -r requirements.txt
```

### 步骤4: 运行数据库迁移
```bash
cd backend
python manage.py makemigrations
python manage.py migrate
```

这将在MariaDB中创建所有必要的表结构。

### 步骤5: 创建超级用户（可选）
```bash
python manage.py createsuperuser
```

### 步骤6: 启动Django开发服务器
```bash
python manage.py runserver
```

## 注意事项

### 安全性
- `.env` 文件包含敏感信息（密码），请确保将其添加到 `.gitignore`
- 生产环境中应使用更安全的密码管理方式

### 数据迁移
如果你有现有的SQLite数据需要迁移到MariaDB：

1. 使用Django的 `dumpdata` 命令导出数据：
   ```bash
   python manage.py dumpdata --natural-foreign --natural-primary -e contenttypes -e auth.Permission --indent 4 > data.json
   ```

2. 切换到MariaDB配置

3. 运行迁移创建表结构

4. 使用 `loaddata` 导入数据：
   ```bash
   python manage.py loaddata data.json
   ```

### 字符编码
- 配置使用 utf8mb4 字符集，支持emoji和特殊字符
- 确保MariaDB服务器配置也使用 utf8mb4

### 连接测试
可以使用以下Python脚本测试数据库连接：

```python
import MySQLdb

try:
    conn = MySQLdb.connect(
        host='127.0.0.1',
        user='root',
        passwd='Ryan@1982',
        db='mentor_db',
        charset='utf8mb4'
    )
    print("数据库连接成功！")
    conn.close()
except Exception as e:
    print(f"数据库连接失败: {e}")
```

## 环境变量配置

`.env` 文件已创建，包含以下配置：
```
DB_NAME=mentor_db
DB_USER=root
DB_PASSWORD=Ryan@1982
DB_HOST=127.0.0.1
DB_PORT=3306
```

如需修改配置，直接编辑 `.env` 文件即可，无需修改代码。

## 故障排除

### 问题1: ModuleNotFoundError: No module named 'MySQLdb'
解决方案：安装 mysqlclient
```bash
pip install mysqlclient
```

如果在Windows上安装失败，可能需要安装Visual C++构建工具。

### 问题2: Access denied for user 'root'@'localhost'
解决方案：检查密码是否正确，确保MariaDB用户权限配置正确。

### 问题3: Can't connect to MySQL server on '127.0.0.1'
解决方案：
- 确认MariaDB服务正在运行
- 检查防火墙设置
- 确认端口3306未被占用

### 问题4: 字符编码问题
解决方案：确保MariaDB配置文件（my.ini或my.cnf）中设置：
```
[client]
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4

[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```
