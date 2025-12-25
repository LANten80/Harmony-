# 工单系统 Java 后端

## 项目简介

这是一个基于 Spring Boot 3.2.0 的工单系统后端服务，提供用户认证、工单管理等功能的 RESTful API。

## 技术栈

- **框架**: Spring Boot 3.2.0
- **数据库**: MySQL 8.0+
- **ORM**: Spring Data JPA
- **安全**: Spring Security (BCrypt密码加密) + JWT
- **构建工具**: Maven
- **Java版本**: 17

## 项目结构

```
src/main/java/com/example/workordersystem/
├── WorkOrderSystemApplication.java    # 启动类
├── config/                            # 配置类
│   ├── SecurityConfig.java           # 安全配置
│   └── WebConfig.java                # Web配置（CORS）
├── controller/                        # 控制器层
│   ├── AuthController.java           # 认证控制器
│   ├── UserController.java           # 用户控制器
│   ├── TaskController.java           # 工单控制器
│   └── GlobalExceptionHandler.java   # 全局异常处理
├── service/                           # 服务层
│   ├── UserService.java              # 用户服务
│   └── TaskService.java              # 工单服务
├── repository/                        # 数据访问层
│   ├── UserRepository.java           # 用户Repository
│   ├── TaskRepository.java           # 工单Repository
│   └── UserTokenRepository.java      # Token Repository
├── entity/                            # 实体类
│   ├── User.java                     # 用户实体
│   ├── Task.java                     # 工单实体
│   └── UserToken.java                # Token实体
├── dto/                               # 数据传输对象
│   ├── LoginRequest.java             # 登录请求
│   ├── RegisterRequest.java          # 注册请求
│   ├── UserInfoResponse.java         # 用户信息响应
│   ├── TaskRequest.java              # 工单请求
│   └── TaskResponse.java             # 工单响应
├── common/                            # 公共类
│   └── ApiResponse.java              # 统一响应类
└── util/                              # 工具类
    ├── JwtUtil.java                  # JWT工具
    └── IdGenerator.java              # ID生成器
```

## 快速开始

### 1. 环境要求

- JDK 17+
- Maven 3.6+
- MySQL 8.0+

### 2. 数据库配置

1. 创建数据库：
```sql
CREATE DATABASE work_order_system;
```

2. 执行初始化脚本：
```bash
mysql -u root -p work_order_system < database/init.sql
```

3. 修改配置文件 `src/main/resources/application.yml`：
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/work_order_system?...
    username: root
    password: your_password  # 修改为你的MySQL密码
```

### 3. JWT配置

修改 `application.yml` 中的JWT配置：
```yaml
jwt:
  secret: your-secret-key-change-this-in-production  # 修改为安全的密钥
  expiration: 86400000  # Token过期时间（毫秒）
```

### 4. 运行项目

```bash
# 使用Maven运行
mvn spring-boot:run

# 或打包后运行
mvn clean package
java -jar target/work-order-system-1.0.0.jar
```

项目启动后，访问：`http://localhost:8080/api`

## API接口文档

### 认证接口

#### 1. 用户注册
```
POST /api/auth/register
Content-Type: application/json

{
  "username": "testuser",
  "phone": "13800138000",
  "password": "password123"
}
```

响应：
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "id": "user_xxx",
    "username": "testuser",
    "phone": "13800138000",
    "registerTime": "2024-01-01T10:00:00",
    "token": "jwt_token_here"
  }
}
```

#### 2. 用户登录
```
POST /api/auth/login
Content-Type: application/json

{
  "account": "testuser",  // 用户名或手机号
  "password": "password123",
  "rememberMe": false
}
```

响应：
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "id": "user_xxx",
    "username": "testuser",
    "phone": "13800138000",
    "registerTime": "2024-01-01T10:00:00",
    "lastLoginTime": "2024-01-01T12:00:00",
    "token": "jwt_token_here"
  }
}
```

### 用户接口

#### 获取用户信息
```
GET /api/user/info
Authorization: Bearer {token}
```

#### 根据ID获取用户信息
```
GET /api/user/{userId}
```

### 工单接口

#### 1. 创建工单
```
POST /api/task/create
Authorization: Bearer {token}
Content-Type: application/json

{
  "taskName": "完成项目文档",
  "description": "编写项目文档",
  "progressValue": 0,
  "status": "pending",
  "priority": "high",
  "dueDate": "2024-01-31T23:59:59",
  "category": "文档",
  "tags": ["重要", "紧急"]
}
```

#### 2. 更新工单
```
PUT /api/task/{taskId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "taskName": "完成项目文档",
  "description": "编写项目文档",
  "progressValue": 50,
  "status": "in_progress",
  "priority": "high"
}
```

#### 3. 删除工单
```
DELETE /api/task/{taskId}
Authorization: Bearer {token}
```

#### 4. 获取工单详情
```
GET /api/task/{taskId}
Authorization: Bearer {token}
```

#### 5. 获取工单列表（分页）
```
GET /api/task/list?page=0&size=10
Authorization: Bearer {token}
```

#### 6. 根据状态获取工单列表
```
GET /api/task/status/{status}
Authorization: Bearer {token}
```

状态值：`pending`, `in_progress`, `completed`, `cancelled`

#### 7. 根据优先级获取工单列表
```
GET /api/task/priority/{priority}
Authorization: Bearer {token}
```

优先级值：`low`, `medium`, `high`, `urgent`

## 统一响应格式

所有API接口都使用统一的响应格式：

```json
{
  "code": 200,           // 状态码
  "message": "操作成功",  // 消息
  "data": {}             // 数据
}
```

状态码说明：
- `200`: 成功
- `400`: 请求参数错误
- `401`: 未授权
- `404`: 资源不存在
- `500`: 服务器错误

## 认证说明

1. 登录或注册成功后，会返回JWT Token
2. 需要认证的接口，在请求头中添加：
   ```
   Authorization: Bearer {token}
   ```
3. Token默认有效期为24小时

## 数据库设计

详见 `MySQL数据库设计文档.md`

## 注意事项

1. **生产环境配置**
   - 修改JWT密钥为强随机字符串
   - 修改数据库密码
   - 配置CORS允许的前端地址
   - 启用HTTPS

2. **密码安全**
   - 使用BCrypt加密存储密码
   - 前端传输密码时建议使用HTTPS

3. **性能优化**
   - 可以添加Redis缓存用户信息和Token
   - 对于大数据量，考虑分页查询优化

4. **错误处理**
   - 所有异常都会被全局异常处理器捕获
   - 返回统一的错误响应格式

## 测试

使用Postman或其他API测试工具测试接口：

1. 先注册或登录获取Token
2. 使用Token访问需要认证的接口

## 常见问题

### Q: 启动失败，提示数据库连接错误
A: 检查 `application.yml` 中的数据库配置是否正确，确保MySQL服务已启动。

### Q: Token验证失败
A: 检查Token是否过期，或JWT密钥是否一致。

### Q: CORS跨域问题
A: 在 `WebConfig.java` 中配置允许的前端地址。

## 许可证

MIT License

