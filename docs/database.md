# 数据库设计文档

## 概述

本项目使用 **MariaDB** 存储持久化用户数据，使用 **Redis** 存储用户会话状态和临时数据。

---

## MariaDB 数据库设计

### 数据库创建

```sql
CREATE DATABASE IF NOT EXISTS seed_platform
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE seed_platform;
```

### 1. 用户基础表 (users)

存储用户的核心账户信息。

```sql
CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
  username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
  email VARCHAR(100) NOT NULL UNIQUE COMMENT '邮箱地址',
  password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希值（bcrypt/argon2）',
  display_name VARCHAR(100) DEFAULT NULL COMMENT '显示名称/昵称',
  avatar_url VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
  status TINYINT DEFAULT 1 COMMENT '账户状态：0=禁用，1=正常，2=待验证',
  email_verified BOOLEAN DEFAULT FALSE COMMENT '邮箱是否已验证',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  last_login_at TIMESTAMP NULL DEFAULT NULL COMMENT '最后登录时间',
  INDEX idx_username (username),
  INDEX idx_email (email),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户基础信息表';
```

**字段说明：**
- `id`: 主键，自增 BIGINT，支持大规模用户
- `username`: 用户名，唯一索引，用于登录
- `email`: 邮箱，唯一索引，可用于找回密码
- `password_hash`: 密码哈希值，推荐使用 bcrypt 或 argon2
- `display_name`: 用户昵称，可与 username 不同
- `avatar_url`: 头像地址，可存储 OSS/CDN 链接
- `status`: 账户状态枚举
- `email_verified`: 邮箱验证标识
- `last_login_at`: 记录最后登录时间，用于安全审计

### 2. 用户会话表 (user_sessions)

存储持久化的登录会话信息（可选，若全部使用 Redis 可省略）。

```sql
CREATE TABLE user_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '会话ID',
  user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  token VARCHAR(255) NOT NULL UNIQUE COMMENT '会话令牌（JWT token或UUID）',
  device_info VARCHAR(500) DEFAULT NULL COMMENT '设备信息（User-Agent等）',
  ip_address VARCHAR(45) DEFAULT NULL COMMENT '登录IP地址',
  expires_at TIMESTAMP NOT NULL COMMENT '过期时间',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  INDEX idx_user_id (user_id),
  INDEX idx_token (token),
  INDEX idx_expires_at (expires_at),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户会话记录表';
```

**字段说明：**
- `token`: 会话令牌，可以是 JWT 或随机生成的 UUID
- `device_info`: 记录登录设备信息，便于用户查看登录历史
- `ip_address`: 登录 IP，支持 IPv6（VARCHAR(45)）
- `expires_at`: 会话过期时间，用于定期清理

### 3. 用户扩展信息表 (user_profiles)（可选）

存储用户的额外个人信息。

```sql
CREATE TABLE user_profiles (
  user_id BIGINT UNSIGNED PRIMARY KEY COMMENT '用户ID',
  bio TEXT DEFAULT NULL COMMENT '个人简介',
  phone VARCHAR(20) DEFAULT NULL COMMENT '手机号码',
  gender TINYINT DEFAULT 0 COMMENT '性别：0=未设置，1=男，2=女',
  birth_date DATE DEFAULT NULL COMMENT '生日',
  country VARCHAR(50) DEFAULT NULL COMMENT '国家',
  timezone VARCHAR(50) DEFAULT 'Asia/Shanghai' COMMENT '时区',
  language VARCHAR(10) DEFAULT 'zh-CN' COMMENT '偏好语言',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户扩展信息表';
```

### 4. 用户操作日志表 (user_logs)（可选）

记录用户的关键操作，用于审计和安全分析。

```sql
CREATE TABLE user_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '日志ID',
  user_id BIGINT UNSIGNED DEFAULT NULL COMMENT '用户ID（未登录操作可为空）',
  action VARCHAR(50) NOT NULL COMMENT '操作类型：login, logout, register, password_change等',
  ip_address VARCHAR(45) DEFAULT NULL COMMENT 'IP地址',
  user_agent VARCHAR(500) DEFAULT NULL COMMENT '浏览器User-Agent',
  status TINYINT DEFAULT 1 COMMENT '操作结果：0=失败，1=成功',
  error_message TEXT DEFAULT NULL COMMENT '失败原因（如有）',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  INDEX idx_user_id (user_id),
  INDEX idx_action (action),
  INDEX idx_created_at (created_at),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户操作日志表';
```

---

## Redis 数据设计

### 1. 用户会话 (Session)

**Key 格式**: `session:{session_token}`

**数据结构**: Hash

**字段**:
```
user_id: 用户ID
username: 用户名
login_time: 登录时间戳
ip_address: 登录IP
device_info: 设备信息
```

**TTL**: 7200秒（2小时）或根据需求调整

**示例**:
```redis
HSET session:a1b2c3d4-uuid user_id 10001
HSET session:a1b2c3d4-uuid username "zhangsan"
HSET session:a1b2c3d4-uuid login_time 1704672000
EXPIRE session:a1b2c3d4-uuid 7200
```

### 2. 用户在线状态

**Key 格式**: `user:online:{user_id}`

**数据结构**: String（存储最后活跃时间戳）

**TTL**: 600秒（10分钟）

**示例**:
```redis
SET user:online:10001 1704672000 EX 600
```

### 3. 登录失败计数（防暴力破解）

**Key 格式**: `login:failed:{username_or_ip}`

**数据结构**: String（失败次数）

**TTL**: 1800秒（30分钟）

**示例**:
```redis
INCR login:failed:zhangsan
EXPIRE login:failed:zhangsan 1800
```

### 4. 邮箱验证码（注册/找回密码）

**Key 格式**: `verify:email:{email}:{purpose}`

**数据结构**: String（验证码）

**TTL**: 600秒（10分钟）

**示例**:
```redis
SET verify:email:user@example.com:register 123456 EX 600
```

### 5. 用户 Token 黑名单（注销/踢出）

**Key 格式**: `token:blacklist:{token}`

**数据结构**: String（注销时间戳）

**TTL**: 与 token 原有效期相同

**示例**:
```redis
SET token:blacklist:a1b2c3d4-uuid 1704672000 EX 7200
```

---

## 数据库初始化脚本

### 完整 DDL

```sql
-- 创建数据库
CREATE DATABASE IF NOT EXISTS seed_platform
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE seed_platform;

-- 用户基础表
CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
  username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
  email VARCHAR(100) NOT NULL UNIQUE COMMENT '邮箱地址',
  password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希值',
  display_name VARCHAR(100) DEFAULT NULL COMMENT '显示名称',
  avatar_url VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
  status TINYINT DEFAULT 1 COMMENT '状态：0=禁用，1=正常，2=待验证',
  email_verified BOOLEAN DEFAULT FALSE COMMENT '邮箱已验证',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  last_login_at TIMESTAMP NULL DEFAULT NULL COMMENT '最后登录时间',
  INDEX idx_username (username),
  INDEX idx_email (email),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户基础信息表';

-- 用户会话表（可选）
CREATE TABLE user_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '会话ID',
  user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
  token VARCHAR(255) NOT NULL UNIQUE COMMENT '会话令牌',
  device_info VARCHAR(500) DEFAULT NULL COMMENT '设备信息',
  ip_address VARCHAR(45) DEFAULT NULL COMMENT '登录IP',
  expires_at TIMESTAMP NOT NULL COMMENT '过期时间',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  INDEX idx_user_id (user_id),
  INDEX idx_token (token),
  INDEX idx_expires_at (expires_at),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户会话记录表';

-- 用户扩展信息表（可选）
CREATE TABLE user_profiles (
  user_id BIGINT UNSIGNED PRIMARY KEY COMMENT '用户ID',
  bio TEXT DEFAULT NULL COMMENT '个人简介',
  phone VARCHAR(20) DEFAULT NULL COMMENT '手机号码',
  gender TINYINT DEFAULT 0 COMMENT '性别：0=未设置，1=男，2=女',
  birth_date DATE DEFAULT NULL COMMENT '生日',
  country VARCHAR(50) DEFAULT NULL COMMENT '国家',
  timezone VARCHAR(50) DEFAULT 'Asia/Shanghai' COMMENT '时区',
  language VARCHAR(10) DEFAULT 'zh-CN' COMMENT '语言',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户扩展信息表';

-- 用户操作日志表（可选）
CREATE TABLE user_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '日志ID',
  user_id BIGINT UNSIGNED DEFAULT NULL COMMENT '用户ID',
  action VARCHAR(50) NOT NULL COMMENT '操作类型',
  ip_address VARCHAR(45) DEFAULT NULL COMMENT 'IP地址',
  user_agent VARCHAR(500) DEFAULT NULL COMMENT 'User-Agent',
  status TINYINT DEFAULT 1 COMMENT '状态：0=失败，1=成功',
  error_message TEXT DEFAULT NULL COMMENT '错误信息',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  INDEX idx_user_id (user_id),
  INDEX idx_action (action),
  INDEX idx_created_at (created_at),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户操作日志表';
```

### 测试数据（可选）

```sql
-- 插入测试用户（密码: password123，需要在代码中使用 bcrypt hash）
INSERT INTO users (username, email, password_hash, display_name, status, email_verified)
VALUES 
  ('admin', 'admin@example.com', '$2b$12$abcdefghijklmnopqrstuv', '管理员', 1, TRUE),
  ('testuser', 'test@example.com', '$2b$12$abcdefghijklmnopqrstuv', '测试用户', 1, TRUE);

-- 插入用户扩展信息
INSERT INTO user_profiles (user_id, bio, gender, language)
VALUES 
  (1, '系统管理员账户', 0, 'zh-CN'),
  (2, '普通测试用户', 0, 'zh-CN');
```

---

## 使用说明

### 1. 安装数据库

**MariaDB**:
```bash
# Ubuntu/Debian
sudo apt install mariadb-server

# macOS
brew install mariadb

# Windows
# 从官网下载安装包：https://mariadb.org/download/
```

**Redis**:
```bash
# Ubuntu/Debian
sudo apt install redis-server

# macOS
brew install redis

# Windows
# 从官网下载或使用 WSL
```

### 2. 初始化数据库

```bash
# 登录 MariaDB
mysql -u root -p

# 执行初始化脚本
source /path/to/database.sql

# 或直接导入
mysql -u root -p < docs/database.sql
```

### 3. 创建应用数据库用户

```sql
-- 创建专用用户
CREATE USER 'seed_app'@'localhost' IDENTIFIED BY 'your_password_here';

-- 授予权限
GRANT SELECT, INSERT, UPDATE, DELETE ON seed_platform.* TO 'seed_app'@'localhost';

-- 刷新权限
FLUSH PRIVILEGES;
```

### 4. Python 连接配置示例

**requirements.txt 添加**:
```
pymysql>=1.0.2
redis>=5.0.0
bcrypt>=4.0.1
```

**数据库配置**:
```python
# backend/config.py
import os

DATABASE_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'user': os.getenv('DB_USER', 'seed_app'),
    'password': os.getenv('DB_PASSWORD', 'your_password'),
    'database': os.getenv('DB_NAME', 'seed_platform'),
    'charset': 'utf8mb4'
}

REDIS_CONFIG = {
    'host': os.getenv('REDIS_HOST', 'localhost'),
    'port': int(os.getenv('REDIS_PORT', 6379)),
    'db': int(os.getenv('REDIS_DB', 0)),
    'password': os.getenv('REDIS_PASSWORD', None),
    'decode_responses': True
}
```

---

## 扩展建议

### 后续可增加的表

1. **用户角色表 (user_roles)**: 实现 RBAC 权限控制
2. **第三方登录绑定表 (oauth_bindings)**: 支持 GitHub、Google 登录
3. **用户配额表 (user_quotas)**: 限制 API 调用次数
4. **用户收藏/历史表**: 记录用户使用记录

### Redis 扩展场景

1. **接口限流**: `rate_limit:user:{user_id}:{endpoint}`
2. **缓存用户信息**: `cache:user:{user_id}` 减少数据库查询
3. **分布式锁**: `lock:user:{user_id}` 防止并发修改
4. **消息队列**: 处理异步任务（邮件发送等）

---

## 备份与维护

### 定期备份

```bash
# 备份数据库
mysqldump -u root -p seed_platform > backup_$(date +%Y%m%d).sql

# 恢复数据库
mysql -u root -p seed_platform < backup_20260108.sql
```

### Redis 持久化

在 `redis.conf` 中配置：
```
# RDB 快照
save 900 1
save 300 10

# AOF 日志
appendonly yes
appendfsync everysec
```

---

## 注意事项

1. **密码安全**: 必须使用 bcrypt/argon2 等强哈希算法，禁止明文存储
2. **索引优化**: 根据实际查询场景调整索引
3. **定期清理**: user_sessions 和 user_logs 需定期清理过期数据
4. **SQL 注入防护**: 使用参数化查询，禁止字符串拼接
5. **Redis 安全**: 生产环境必须设置密码，限制访问 IP

---

**版本**: v1.0  
**更新时间**: 2026-01-08  
**维护者**: seed-backend team
