"""
创建MariaDB数据库的Python脚本
"""
import MySQLdb

try:
    # 连接到MariaDB服务器（不指定数据库）
    print("正在连接到MariaDB服务器...")
    conn = MySQLdb.connect(
        host='127.0.0.1',
        user='root',
        passwd='Ryan@1982',
        charset='utf8mb4'
    )
    
    cursor = conn.cursor()
    
    # 创建数据库
    print("正在创建数据库 mentor_db...")
    cursor.execute("CREATE DATABASE IF NOT EXISTS mentor_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
    print("✓ 数据库创建成功！")
    
    # 显示所有数据库
    print("\n当前数据库列表:")
    cursor.execute("SHOW DATABASES")
    for db in cursor.fetchall():
        print(f"  - {db[0]}")
    
    cursor.close()
    conn.close()
    
    # 测试连接到新创建的数据库
    print("\n正在测试连接到 mentor_db...")
    conn = MySQLdb.connect(
        host='127.0.0.1',
        user='root',
        passwd='Ryan@1982',
        db='mentor_db',
        charset='utf8mb4'
    )
    print("✓ 连接到 mentor_db 成功！")
    conn.close()
    
    print("\n数据库设置完成！")
    print("下一步: 运行 python manage.py migrate")
    
except MySQLdb.Error as e:
    print(f"✗ 错误: {e}")
    exit(1)
