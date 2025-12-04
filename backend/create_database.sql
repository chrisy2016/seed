-- MariaDB数据库创建脚本
-- 在MariaDB中执行此脚本以创建数据库

-- 创建数据库
CREATE DATABASE IF NOT EXISTS mentor_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- 授权给root用户（如果需要）
GRANT ALL PRIVILEGES ON mentor_db.* TO 'root'@'localhost';
FLUSH PRIVILEGES;

-- 显示数据库
SHOW DATABASES;
