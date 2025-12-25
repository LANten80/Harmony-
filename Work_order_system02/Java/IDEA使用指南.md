# IntelliJ IDEA 使用指南

## 重要说明

**本项目是 Spring Boot 项目，内置了 Tomcat 服务器，不需要单独配置 Tomcat！**

Spring Boot 会自动启动内置的 Tomcat 服务器，你只需要在 IDEA 中运行项目即可。

## 在 IDEA 中的操作步骤

### 第一步：导入项目

1. **打开 IDEA**
   - 启动 IntelliJ IDEA

2. **导入 Maven 项目**
   - 点击 `File` → `Open`
   - 选择 `Java后端` 文件夹
   - 点击 `OK`

3. **等待 Maven 下载依赖**
   - IDEA 会自动识别这是一个 Maven 项目
   - 右下角会提示 "Maven projects need to be imported"
   - 点击 `Import Maven Project` 或 `Enable Auto-Import`
   - 等待依赖下载完成（可能需要几分钟）

### 第二步：配置数据库

1. **确保 MySQL 已启动**
   - 检查 MySQL 服务是否运行

2. **执行数据库初始化脚本**
   - 在 IDEA 中打开 `database/init.sql`
   - 或者在 MySQL 客户端执行：
     ```bash
     mysql -u root -p < database/init.sql
     ```

3. **修改配置文件**
   - 打开 `src/main/resources/application.yml`
   - 修改数据库密码：
     ```yaml
     spring:
       datasource:
         username: root
         password: 你的MySQL密码  # 修改这里
     ```
   - 修改 JWT 密钥（可选，但建议修改）：
     ```yaml
     jwt:
       secret: 你的安全密钥  # 修改为随机字符串
     ```

### 第三步：运行项目

#### 方法1：直接运行主类（推荐）

1. **找到启动类**
   - 在项目结构中，找到 `src/main/java/com/example/workordersystem/WorkOrderSystemApplication.java`

2. **运行项目**
   - 右键点击 `WorkOrderSystemApplication.java`
   - 选择 `Run 'WorkOrderSystemApplication'`
   - 或者点击类名左侧的绿色三角形 ▶️

3. **查看控制台输出**
   - 在 IDEA 底部的 `Run` 窗口查看日志
   - 看到类似以下输出表示启动成功：
     ```
     Started WorkOrderSystemApplication in X.XXX seconds
     ```

#### 方法2：使用 Maven 运行

1. **打开 Maven 工具窗口**
   - 点击 IDEA 右侧的 `Maven` 标签
   - 或使用快捷键：`Alt + 1`（Windows）或 `Cmd + 1`（Mac）

2. **运行项目**
   - 展开 `work-order-system` → `Plugins` → `spring-boot`
   - 双击 `spring-boot:run`

### 第四步：验证运行

1. **检查端口**
   - 项目默认运行在 `http://localhost:8080`
   - 如果 8080 端口被占用，可以在 `application.yml` 中修改：
     ```yaml
     server:
       port: 8081  # 修改为其他端口
     ```

2. **测试接口**
   - 在浏览器中访问：`http://localhost:8080/api/auth/login`
   - 或使用 IDEA 内置的 HTTP Client（见下方）

## IDEA 配置说明

### 1. JDK 配置

确保项目使用 JDK 17：

1. **检查项目 JDK**
   - `File` → `Project Structure` (快捷键：`Ctrl + Alt + Shift + S`)
   - 在 `Project` 标签中，检查 `SDK` 是否为 JDK 17
   - 如果不是，点击下拉菜单选择 JDK 17

2. **检查模块 JDK**
   - 在 `Project Structure` 中，选择 `Modules`
   - 选择项目模块，检查 `Language level` 是否为 17

### 2. Maven 配置

1. **检查 Maven 设置**
   - `File` → `Settings` (快捷键：`Ctrl + Alt + S`)
   - 搜索 `Maven`
   - 确认 `Maven home path` 指向正确的 Maven 安装目录
   - 确认 `User settings file` 和 `Local repository` 路径正确

### 3. 编码设置

确保项目使用 UTF-8 编码：

1. **文件编码**
   - `File` → `Settings` → `Editor` → `File Encodings`
   - 设置 `Global Encoding` 和 `Project Encoding` 为 `UTF-8`
   - 设置 `Default encoding for properties files` 为 `UTF-8`

## 使用 IDEA 的 HTTP Client 测试接口

IDEA 内置了 HTTP Client，可以直接测试 API：

1. **创建 HTTP 请求文件**
   - 在项目根目录创建 `http-requests.http` 文件
   - 或使用 IDEA 的 `Tools` → `HTTP Client` → `Create Request in HTTP Client`

2. **编写测试请求**
   
   在 `http-requests.http` 文件中添加：

   ```http
   ### 用户注册
   POST http://localhost:8080/api/auth/register
   Content-Type: application/json

   {
     "username": "testuser",
     "phone": "13800138000",
     "password": "password123"
   }

   ### 用户登录
   POST http://localhost:8080/api/auth/login
   Content-Type: application/json

   {
     "account": "testuser",
     "password": "password123",
     "rememberMe": false
   }

   ### 获取用户信息（需要先登录获取token）
   GET http://localhost:8080/api/user/info
   Authorization: Bearer {{token}}
   ```

3. **运行请求**
   - 点击请求上方的绿色三角形 ▶️
   - 或使用快捷键 `Ctrl + Enter`

## 常见问题解决

### 问题1：Maven 依赖下载失败

**解决方案：**
1. 检查网络连接
2. 配置 Maven 镜像（在 `settings.xml` 中）：
   ```xml
   <mirror>
     <id>aliyun</id>
     <mirrorOf>central</mirrorOf>
     <url>https://maven.aliyun.com/repository/public</url>
   </mirror>
   ```
3. 刷新 Maven：右键项目 → `Maven` → `Reload Project`

### 问题2：端口被占用

**错误信息：**
```
Port 8080 was already in use
```

**解决方案：**
1. 查找占用端口的进程：
   ```bash
   # Windows
   netstat -ano | findstr :8080
   
   # Linux/Mac
   lsof -i :8080
   ```
2. 关闭占用端口的程序
3. 或修改 `application.yml` 中的端口号

### 问题3：数据库连接失败

**错误信息：**
```
Communications link failure
```

**解决方案：**
1. 检查 MySQL 服务是否启动
2. 检查数据库用户名密码是否正确
3. 检查数据库是否已创建（执行 `init.sql`）
4. 检查防火墙是否开放 3306 端口

### 问题4：找不到主类

**解决方案：**
1. 右键项目 → `Maven` → `Reload Project`
2. `File` → `Invalidate Caches` → `Invalidate and Restart`
3. 重新导入项目

### 问题5：编译错误（JDK版本问题）

**解决方案：**
1. 确保安装了 JDK 17
2. `File` → `Project Structure` → `Project` → 设置 `SDK` 为 JDK 17
3. `File` → `Project Structure` → `Modules` → 设置 `Language level` 为 17

## 调试技巧

### 1. 设置断点

1. 在代码行号左侧点击，设置断点（红色圆点）
2. 以 Debug 模式运行：右键 `WorkOrderSystemApplication` → `Debug 'WorkOrderSystemApplication'`
3. 触发断点后，可以查看变量值、单步执行等

### 2. 查看日志

- 在 `Run` 窗口查看控制台日志
- 日志级别在 `application.yml` 中配置：
  ```yaml
  logging:
    level:
      com.example.workordersystem: DEBUG
  ```

### 3. 数据库查看

- 使用 IDEA 的 Database 工具：
  1. `View` → `Tool Windows` → `Database`
  2. 点击 `+` → `Data Source` → `MySQL`
  3. 配置连接信息
  4. 可以查看表结构和数据

## 项目结构说明

在 IDEA 中，项目结构应该如下：

```
work-order-system (项目根目录)
├── .idea/                    # IDEA 配置（自动生成）
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/workordersystem/
│   │   │       ├── WorkOrderSystemApplication.java  # 启动类
│   │   │       ├── config/                          # 配置类
│   │   │       ├── controller/                     # 控制器
│   │   │       ├── service/                        # 服务层
│   │   │       ├── repository/                     # 数据访问层
│   │   │       ├── entity/                        # 实体类
│   │   │       ├── dto/                          # 数据传输对象
│   │   │       ├── common/                       # 公共类
│   │   │       └── util/                         # 工具类
│   │   └── resources/
│   │       └── application.yml                   # 配置文件
├── database/
│   └── init.sql                                  # 数据库脚本
├── pom.xml                                      # Maven 配置
└── README.md                                    # 项目说明
```

## 快速检查清单

在运行项目前，确保：

- [ ] JDK 17 已安装并配置
- [ ] Maven 已安装并配置
- [ ] MySQL 已安装并启动
- [ ] 数据库已创建（执行了 init.sql）
- [ ] application.yml 中的数据库密码已修改
- [ ] Maven 依赖已下载完成
- [ ] 8080 端口未被占用

## 下一步

项目运行成功后：

1. **测试接口**：使用 Postman 或 IDEA 的 HTTP Client
2. **连接前端**：修改 HarmonyOS 项目中的 `BASE_URL`
3. **查看日志**：在 IDEA 的 Run 窗口查看运行日志

## 总结

**重要：Spring Boot 内置了 Tomcat，不需要单独配置！**

你只需要：
1. 在 IDEA 中打开项目
2. 配置数据库连接
3. 运行 `WorkOrderSystemApplication` 主类
4. 项目会自动启动内置的 Tomcat 服务器

就是这么简单！

