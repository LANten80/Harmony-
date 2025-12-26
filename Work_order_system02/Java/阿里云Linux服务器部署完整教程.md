# 阿里云Linux服务器部署完整教程

## 📋 目录
1. [准备工作](#准备工作)
2. [服务器环境配置](#服务器环境配置)
3. [数据库安装与配置](#数据库安装与配置)
4. [项目部署](#项目部署)
5. [防火墙和安全组配置](#防火墙和安全组配置)
6. [服务自启动配置](#服务自启动配置)
7. [域名和SSL配置（可选）](#域名和ssl配置可选)
8. [监控和维护](#监控和维护)
9. [常见问题排查](#常见问题排查)

---

## 准备工作

### 1.1 获取服务器信息
- **服务器公网IP地址**：从阿里云控制台获取
- **服务器用户名**：通常是 `root`（CentOS/Ubuntu）或 `ubuntu`（Ubuntu系统）
- **服务器密码或密钥**：购买服务器时设置的密码，或下载的SSH密钥文件

### 1.2 准备工具
- **SSH客户端**：
  - Windows：PuTTY、Xshell、Windows Terminal
  - Mac/Linux：系统自带终端
- **文件传输工具**：
  - WinSCP（Windows）
  - FileZilla（跨平台）
  - scp命令（命令行）

### 1.3 本地准备
- 确保本地项目可以正常编译运行
- 准备好数据库初始化脚本：`Java/database/init.sql`

---

## 服务器环境配置

### 2.1 连接到服务器

#### Windows用户（使用PuTTY）
1. 打开PuTTY
2. 在"Host Name"输入：`root@你的服务器IP`
3. 端口：`22`
4. 连接类型：`SSH`
5. 点击"Open"
6. 输入密码（输入时不会显示，直接输入后按回车）

#### Mac/Linux用户（使用终端）
```bash
ssh root@你的服务器IP
# 输入密码后按回车
```

### 2.2 更新系统（首次连接后必须执行）

#### CentOS/RHEL系统
```bash
# 更新系统包
yum update -y

# 安装常用工具
yum install -y wget curl vim git
```

#### Ubuntu/Debian系统
```bash
# 更新系统包
apt update && apt upgrade -y

# 安装常用工具
apt install -y wget curl vim git
```

### 2.3 安装JDK 17

#### CentOS/RHEL系统
```bash
# 方法1：使用yum安装OpenJDK（推荐）
yum install -y java-17-openjdk java-17-openjdk-devel

# 验证安装
java -version
javac -version
```

#### Ubuntu/Debian系统
```bash
# 方法1：使用apt安装OpenJDK（推荐）
apt install -y openjdk-17-jdk

# 验证安装
java -version
javac -version
```

#### 配置JAVA_HOME环境变量
```bash
# 查找Java安装路径
which java
readlink -f $(which java)

# 编辑环境变量文件
vim /etc/profile

# 在文件末尾添加以下内容（根据实际路径修改）
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

# 使配置生效
source /etc/profile

# 验证环境变量
echo $JAVA_HOME
```

### 2.4 安装Maven

```bash
# 创建Maven目录
mkdir -p /usr/local/maven
cd /usr/local/maven

# 下载Maven（使用最新稳定版）
wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz

# 如果上面的链接失效，访问 https://maven.apache.org/download.cgi 获取最新下载链接

# 解压
tar -xzf apache-maven-3.9.6-bin.tar.gz

# 重命名（可选，方便管理）
mv apache-maven-3.9.6 maven

# 配置环境变量
vim /etc/profile

# 在文件末尾添加
export MAVEN_HOME=/usr/local/maven/maven
export PATH=$MAVEN_HOME/bin:$PATH

# 使配置生效
source /etc/profile

# 验证安装
mvn -version
```

---

## 数据库安装与配置

### 3.1 安装MySQL 8.0

#### CentOS/RHEL系统
```bash
# 下载MySQL官方Yum仓库
wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm

# 安装仓库
rpm -ivh mysql80-community-release-el7-3.noarch.rpm

# 安装MySQL服务器
yum install -y mysql-server

# 启动MySQL服务
systemctl start mysqld

# 设置开机自启
systemctl enable mysqld

# 查看临时密码（重要！）
grep 'temporary password' /var/log/mysqld.log
```

#### Ubuntu/Debian系统
```bash
# 更新包列表
apt update

# 安装MySQL服务器
apt install -y mysql-server

# 启动MySQL服务
systemctl start mysql

# 设置开机自启
systemctl enable mysql

# 运行安全配置脚本
mysql_secure_installation
```

### 3.2 配置MySQL

```bash
# 登录MySQL（CentOS需要先使用临时密码）
mysql -u root -p

# 如果忘记临时密码，可以重置（CentOS）
# 停止MySQL服务
systemctl stop mysqld

# 跳过权限表启动
mysqld_safe --skip-grant-tables &

# 登录MySQL（无需密码）
mysql -u root

# 重置root密码
ALTER USER 'root'@'localhost' IDENTIFIED BY '你的新密码';
FLUSH PRIVILEGES;
exit;

# 重启MySQL服务
systemctl restart mysqld
```

### 3.3 创建数据库和用户

```sql
-- 登录MySQL
mysql -u root -p

-- 创建数据库
CREATE DATABASE IF NOT EXISTS work_order_system 
DEFAULT CHARACTER SET utf8mb4 
DEFAULT COLLATE utf8mb4_unicode_ci;

-- 创建专用用户（推荐，更安全）
CREATE USER 'workorder'@'localhost' IDENTIFIED BY '你的数据库密码';
GRANT ALL PRIVILEGES ON work_order_system.* TO 'workorder'@'localhost';
FLUSH PRIVILEGES;

-- 或者允许远程连接（如果需要）
CREATE USER 'workorder'@'%' IDENTIFIED BY '你的数据库密码';
GRANT ALL PRIVILEGES ON work_order_system.* TO 'workorder'@'%';
FLUSH PRIVILEGES;

-- 退出
exit;
```

### 3.4 导入数据库初始化脚本

```bash
# 方法1：如果脚本文件在服务器上
mysql -u workorder -p work_order_system < /path/to/init.sql

# 方法2：直接在MySQL中执行
mysql -u workorder -p work_order_system
source /path/to/init.sql;
exit;
```

### 3.5 验证数据库

```bash
mysql -u workorder -p work_order_system

# 在MySQL中执行
SHOW TABLES;
SELECT COUNT(*) FROM users;
exit;
```

---

## 项目部署

### 4.1 上传项目文件到服务器

#### 方法1：使用WinSCP（Windows推荐）
1. 打开WinSCP
2. 新建会话：
   - 协议：`SFTP`
   - 主机名：`你的服务器IP`
   - 用户名：`root`
   - 密码：`你的服务器密码`
3. 连接后，将本地 `Java` 文件夹上传到服务器的 `/opt/work-order-system` 目录

#### 方法2：使用scp命令（命令行）
```bash
# 在本地项目目录执行
scp -r Java root@你的服务器IP:/opt/work-order-system
```

#### 方法3：使用Git（如果项目在Git仓库）
```bash
# 在服务器上执行
cd /opt
git clone 你的Git仓库地址 work-order-system
cd work-order-system/Java
```

### 4.2 在服务器上编译项目

```bash
# 进入项目目录
cd /opt/work-order-system/Java

# 清理并打包项目
mvn clean package -DskipTests

# 打包成功后，JAR文件会在 target 目录
ls -lh target/*.jar
```

### 4.3 修改配置文件

```bash
# 编辑配置文件
vim src/main/resources/application.yml
```

**需要修改的配置项：**

```yaml
server:
  port: 8080
  servlet:
    context-path: /api

spring:
  application:
    name: work-order-system

  # 数据源配置 - 修改这里！
  datasource:
    url: jdbc:mysql://localhost:3306/work_order_system?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
    username: workorder  # 改为你创建的数据库用户
    password: 你的数据库密码  # 改为你的数据库密码
    driver-class-name: com.mysql.cj.jdbc.Driver
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000

  # JPA配置
  jpa:
    hibernate:
      ddl-auto: update  # 生产环境建议改为 validate
    show-sql: false  # 生产环境建议关闭SQL日志
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQL8Dialect
        format_sql: false

# JWT配置 - 修改这里！
jwt:
  secret: 你的安全密钥  # 改为一个复杂的随机字符串（至少32位）
  expiration: 86400000  # 24小时（毫秒）

# 日志配置
logging:
  level:
    root: INFO
    com.example.workordersystem: INFO  # 生产环境建议改为INFO
    org.springframework.web: INFO
    org.hibernate.SQL: INFO  # 生产环境建议关闭
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  file:
    name: /opt/work-order-system/logs/application.log  # 添加日志文件输出
```

**保存并退出：** 按 `Esc`，输入 `:wq`，按回车

### 4.4 重新打包项目

```bash
# 重新打包
mvn clean package -DskipTests
```

### 4.5 创建运行目录和日志目录

```bash
# 创建应用运行目录
mkdir -p /opt/work-order-system/app
mkdir -p /opt/work-order-system/logs

# 复制JAR文件到运行目录
cp target/work-order-system-1.0.0.jar /opt/work-order-system/app/

# 设置权限
chmod 755 /opt/work-order-system/app/*.jar
```

### 4.6 测试运行项目

```bash
# 进入运行目录
cd /opt/work-order-system/app

# 运行项目（前台运行，用于测试）
java -jar work-order-system-1.0.0.jar

# 如果看到以下信息，说明启动成功：
# Started WorkOrderSystemApplication in X.XXX seconds
# Tomcat started on port(s): 8080 (http)

# 按 Ctrl+C 停止服务
```

### 4.7 验证服务是否正常

**在另一个终端窗口或本地浏览器测试：**

```bash
# 测试健康检查（如果有的话）
curl http://你的服务器IP:8080/api/health

# 或者测试注册接口
curl -X POST http://你的服务器IP:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","phone":"13800138000","password":"test123456"}'
```

---

## 防火墙和安全组配置

### 5.1 配置服务器防火墙

#### CentOS/RHEL（firewalld）
```bash
# 查看防火墙状态
systemctl status firewalld

# 如果防火墙未启动，启动防火墙
systemctl start firewalld
systemctl enable firewalld

# 开放8080端口
firewall-cmd --permanent --add-port=8080/tcp

# 如果使用MySQL远程连接，开放3306端口（可选）
firewall-cmd --permanent --add-port=3306/tcp

# 重新加载防火墙规则
firewall-cmd --reload

# 查看开放的端口
firewall-cmd --list-ports
```

#### Ubuntu/Debian（ufw）
```bash
# 查看防火墙状态
ufw status

# 开放8080端口
ufw allow 8080/tcp

# 如果使用MySQL远程连接，开放3306端口（可选）
ufw allow 3306/tcp

# 启用防火墙（如果未启用）
ufw enable

# 查看防火墙规则
ufw status numbered
```

### 5.2 配置阿里云安全组（重要！）

1. **登录阿里云控制台**
   - 访问：https://ecs.console.aliyun.com

2. **进入ECS实例管理**
   - 点击左侧"实例与镜像" → "实例"
   - 找到你的服务器实例

3. **配置安全组规则**
   - 点击实例ID进入详情页
   - 点击"安全组"标签
   - 点击安全组ID进入安全组规则配置

4. **添加入站规则**
   - 点击"添加安全组规则"
   - 配置如下：
     - **规则方向**：入方向
     - **授权策略**：允许
     - **优先级**：1（数字越小优先级越高）
     - **协议类型**：自定义TCP
     - **端口范围**：8080/8080
     - **授权对象**：0.0.0.0/0（允许所有IP访问，生产环境建议限制IP）
     - **描述**：工单系统后端服务端口
   - 点击"保存"

5. **如果需要远程连接MySQL（可选）**
   - 同样添加规则，端口范围：3306/3306
   - **注意**：生产环境不建议开放3306端口，使用SSH隧道更安全

---

## 服务自启动配置

### 6.1 创建systemd服务文件

```bash
# 创建服务文件
vim /etc/systemd/system/work-order-system.service
```

**文件内容：**

```ini
[Unit]
Description=Work Order System Backend Service
After=network.target mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/work-order-system/app
ExecStart=/usr/bin/java -jar -Xms512m -Xmx1024m /opt/work-order-system/app/work-order-system-1.0.0.jar
ExecStop=/bin/kill -15 $MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=work-order-system

# 环境变量（如果需要）
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk"
Environment="TZ=Asia/Shanghai"

[Install]
WantedBy=multi-user.target
```

**保存并退出：** 按 `Esc`，输入 `:wq`，按回车

### 6.2 启用和启动服务

```bash
# 重新加载systemd配置
systemctl daemon-reload

# 启用服务（开机自启）
systemctl enable work-order-system

# 启动服务
systemctl start work-order-system

# 查看服务状态
systemctl status work-order-system

# 查看服务日志
journalctl -u work-order-system -f
```

### 6.3 常用服务管理命令

```bash
# 启动服务
systemctl start work-order-system

# 停止服务
systemctl stop work-order-system

# 重启服务
systemctl restart work-order-system

# 查看服务状态
systemctl status work-order-system

# 查看服务日志（实时）
journalctl -u work-order-system -f

# 查看最近100行日志
journalctl -u work-order-system -n 100

# 禁用开机自启
systemctl disable work-order-system

# 启用开机自启
systemctl enable work-order-system
```

---

## 域名和SSL配置（可选）

### 7.1 配置域名解析

1. **在域名服务商处添加A记录**
   - 记录类型：A
   - 主机记录：`api`（或你想要的子域名）
   - 记录值：你的服务器公网IP
   - TTL：600（或默认值）

2. **等待DNS解析生效**
   - 通常需要几分钟到几小时
   - 可以使用 `nslookup api.你的域名.com` 验证

### 7.2 安装Nginx作为反向代理

#### CentOS/RHEL
```bash
# 安装Nginx
yum install -y nginx

# 启动Nginx
systemctl start nginx
systemctl enable nginx
```

#### Ubuntu/Debian
```bash
# 安装Nginx
apt install -y nginx

# 启动Nginx
systemctl start nginx
systemctl enable nginx
```

### 7.3 配置Nginx反向代理

```bash
# 创建Nginx配置文件
vim /etc/nginx/conf.d/work-order-system.conf
```

**文件内容：**

```nginx
server {
    listen 80;
    server_name api.你的域名.com;  # 改为你的域名

    # 日志配置
    access_log /var/log/nginx/work-order-system-access.log;
    error_log /var/log/nginx/work-order-system-error.log;

    # 反向代理到Spring Boot应用
    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 健康检查（如果有）
    location /health {
        proxy_pass http://localhost:8080/health;
    }
}
```

**保存并退出，然后测试配置：**

```bash
# 测试Nginx配置
nginx -t

# 重新加载Nginx配置
systemctl reload nginx
```

### 7.4 配置SSL证书（使用Let's Encrypt免费证书）

```bash
# 安装Certbot
# CentOS/RHEL
yum install -y certbot python3-certbot-nginx

# Ubuntu/Debian
apt install -y certbot python3-certbot-nginx

# 获取SSL证书
certbot --nginx -d api.你的域名.com

# 按照提示操作，Certbot会自动配置Nginx
```

**更新后的Nginx配置会自动包含SSL配置**

### 7.5 修改Spring Boot配置支持HTTPS（如果需要）

如果需要Spring Boot直接支持HTTPS，需要：
1. 获取SSL证书文件（.crt和.key）
2. 修改 `application.yml` 添加SSL配置
3. 重启服务

---

## 监控和维护

### 8.1 查看应用日志

```bash
# 查看systemd日志
journalctl -u work-order-system -f

# 查看应用日志文件（如果配置了文件输出）
tail -f /opt/work-order-system/logs/application.log

# 查看最近100行日志
journalctl -u work-order-system -n 100
```

### 8.2 监控服务状态

```bash
# 检查服务是否运行
systemctl is-active work-order-system

# 检查端口是否监听
netstat -tlnp | grep 8080
# 或
ss -tlnp | grep 8080

# 检查Java进程
ps aux | grep java
```

### 8.3 性能监控

```bash
# 查看系统资源使用情况
top
# 或
htop  # 需要先安装：yum install htop 或 apt install htop

# 查看内存使用
free -h

# 查看磁盘使用
df -h

# 查看Java进程资源使用
jps -lvm  # 需要JDK工具
```

### 8.4 备份数据库

```bash
# 创建备份脚本
vim /opt/work-order-system/backup-db.sh
```

**脚本内容：**

```bash
#!/bin/bash
BACKUP_DIR="/opt/work-order-system/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="work_order_system"
DB_USER="workorder"
DB_PASS="你的数据库密码"

mkdir -p $BACKUP_DIR

# 备份数据库
mysqldump -u$DB_USER -p$DB_PASS $DB_NAME > $BACKUP_DIR/${DB_NAME}_${DATE}.sql

# 压缩备份文件
gzip $BACKUP_DIR/${DB_NAME}_${DATE}.sql

# 删除7天前的备份
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Database backup completed: ${DB_NAME}_${DATE}.sql.gz"
```

**设置执行权限并测试：**

```bash
chmod +x /opt/work-order-system/backup-db.sh

# 测试执行
/opt/work-order-system/backup-db.sh
```

**设置定时任务（每天凌晨2点备份）：**

```bash
# 编辑crontab
crontab -e

# 添加以下行
0 2 * * * /opt/work-order-system/backup-db.sh >> /opt/work-order-system/logs/backup.log 2>&1
```

### 8.5 更新应用

```bash
# 1. 停止服务
systemctl stop work-order-system

# 2. 备份当前版本
cp /opt/work-order-system/app/work-order-system-1.0.0.jar /opt/work-order-system/app/work-order-system-1.0.0.jar.backup

# 3. 上传新版本JAR文件到服务器

# 4. 替换JAR文件
cp /path/to/new/work-order-system-1.0.0.jar /opt/work-order-system/app/

# 5. 启动服务
systemctl start work-order-system

# 6. 查看日志确认启动成功
journalctl -u work-order-system -f
```

---

## 常见问题排查

### 9.1 服务无法启动

**检查步骤：**

```bash
# 1. 查看服务状态
systemctl status work-order-system

# 2. 查看详细日志
journalctl -u work-order-system -n 50

# 3. 检查端口是否被占用
netstat -tlnp | grep 8080

# 4. 检查Java环境
java -version

# 5. 检查JAR文件是否存在
ls -lh /opt/work-order-system/app/*.jar

# 6. 手动运行JAR文件查看错误
cd /opt/work-order-system/app
java -jar work-order-system-1.0.0.jar
```

**常见原因：**
- 端口被占用：修改 `application.yml` 中的端口，或停止占用端口的进程
- 数据库连接失败：检查数据库配置和数据库服务状态
- 内存不足：增加JVM内存参数或服务器内存

### 9.2 数据库连接失败

**检查步骤：**

```bash
# 1. 检查MySQL服务状态
systemctl status mysql
# 或
systemctl status mysqld

# 2. 测试数据库连接
mysql -u workorder -p work_order_system

# 3. 检查数据库用户权限
mysql -u root -p
SHOW GRANTS FOR 'workorder'@'localhost';

# 4. 检查防火墙是否阻止
firewall-cmd --list-all
# 或
ufw status
```

**解决方案：**
- 确保MySQL服务运行：`systemctl start mysql`
- 检查用户名和密码是否正确
- 检查数据库是否存在：`SHOW DATABASES;`

### 9.3 无法访问服务

**检查步骤：**

```bash
# 1. 检查服务是否运行
systemctl status work-order-system

# 2. 检查端口是否监听
netstat -tlnp | grep 8080

# 3. 检查服务器防火墙
firewall-cmd --list-ports
# 或
ufw status

# 4. 在服务器本地测试
curl http://localhost:8080/api/health

# 5. 检查阿里云安全组规则
# 登录阿里云控制台检查安全组配置
```

**解决方案：**
- 开放防火墙端口：`firewall-cmd --permanent --add-port=8080/tcp && firewall-cmd --reload`
- 在阿里云安全组中添加8080端口规则
- 检查服务是否正常启动

### 9.4 性能问题

**优化建议：**

```bash
# 1. 调整JVM参数（在systemd服务文件中）
# 增加内存
ExecStart=/usr/bin/java -jar -Xms1024m -Xmx2048m ...

# 2. 检查系统资源
top
free -h
df -h

# 3. 优化数据库连接池（在application.yml中）
# 根据实际情况调整连接池大小

# 4. 查看慢查询日志（MySQL）
# 在MySQL配置文件中启用慢查询日志
```

### 9.5 日志文件过大

**解决方案：**

```bash
# 1. 配置日志轮转
vim /etc/logrotate.d/work-order-system
```

**文件内容：**

```
/opt/work-order-system/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
```

---

## 📝 部署检查清单

部署完成后，请按照以下清单检查：

- [ ] JDK 17已安装并配置环境变量
- [ ] Maven已安装并配置环境变量
- [ ] MySQL已安装并启动
- [ ] 数据库已创建并导入初始化脚本
- [ ] 项目已编译打包成功
- [ ] 配置文件已修改（数据库连接、JWT密钥等）
- [ ] 服务已创建并设置为开机自启
- [ ] 服务已启动并运行正常
- [ ] 防火墙已开放8080端口
- [ ] 阿里云安全组已配置8080端口规则
- [ ] 可以通过公网IP访问服务
- [ ] 日志输出正常
- [ ] 数据库备份脚本已配置（可选）
- [ ] 域名和SSL已配置（可选）

---

## 🎉 部署完成

恭喜！你的后端服务已经成功部署到阿里云服务器。

**访问地址：**
- HTTP：`http://你的服务器IP:8080/api`
- 如果配置了域名：`http://api.你的域名.com/api`
- 如果配置了SSL：`https://api.你的域名.com/api`

**下一步：**
1. 更新前端应用的API地址
2. 测试所有功能是否正常
3. 配置监控和告警（可选）
4. 定期备份数据库

---

## 📞 需要帮助？

如果遇到问题，请：
1. 查看服务日志：`journalctl -u work-order-system -f`
2. 检查常见问题排查章节
3. 查看应用日志文件
4. 检查系统资源使用情况

---

**文档版本：** v1.0  
**最后更新：** 2024年





