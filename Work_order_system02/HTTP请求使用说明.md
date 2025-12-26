# HTTP请求到Java后端使用说明

## 概述

本项目已集成HTTP请求功能，可以连接到Java后端服务器。以下是详细的使用说明。

## 已完成的配置

### 1. 网络权限配置
已在 `AppScope/app.json5` 中添加了网络权限：
```json
"reqPermissions": [
  {
    "name": "ohos.permission.INTERNET"
  }
]
```

### 2. 后端API地址配置
在 `entry/src/main/ets/common/constants/CommonConstant.ets` 中配置了后端API基础URL：
```typescript
export const BASE_URL = 'http://your-backend-server.com:8080/api';
```

**重要：请将 `BASE_URL` 修改为你的实际Java后端地址！**

### 3. HTTP工具类
创建了 `HttpUtil` 工具类（`entry/src/main/ets/common/utils/HttpUtil.ets`），提供以下功能：
- GET、POST、PUT、DELETE请求
- 自动处理请求头和响应
- Token认证支持
- 错误处理和超时控制

### 4. API服务类
创建了 `ApiService` 类（`entry/src/main/ets/common/api/ApiService.ets`），封装了常用的API调用方法。

## 使用步骤

### 步骤1：配置后端地址

编辑 `entry/src/main/ets/common/constants/CommonConstant.ets`，修改 `BASE_URL`：

```typescript
// 修改为你的Java后端地址
export const BASE_URL = 'http://192.168.1.100:8080/api';  // 示例地址
```

### 步骤2：使用HTTP工具类发送请求

#### 方式1：直接使用HttpUtil

```typescript
import { httpUtil } from '../common/utils/HttpUtil';

// GET请求
const response = await httpUtil.get('/user/info', { userId: '123' });

// POST请求
const response = await httpUtil.post('/auth/login', {
  account: 'username',
  password: 'password'
});

// PUT请求
const response = await httpUtil.put('/user/update', {
  username: 'newName'
});

// DELETE请求
const response = await httpUtil.delete('/user/delete', { userId: '123' });
```

#### 方式2：使用ApiService（推荐）

```typescript
import { apiService } from '../common/api/ApiService';

// 登录
const loginResponse = await apiService.login({
  account: 'username',
  password: 'password',
  rememberMe: true
});

// 注册
const registerResponse = await apiService.register({
  username: 'newuser',
  phone: '13800138000',
  password: 'password123'
});

// 获取用户信息
const userInfo = await apiService.getUserInfo('userId');

// 退出登录
await apiService.logout();
```

### 步骤3：在AuthService中使用HTTP请求

已创建示例文件 `AuthServiceWithHttp.ets`，展示了如何将认证服务改为使用HTTP请求。

你可以：
1. 直接使用 `AuthServiceWithHttp` 类
2. 或者将 `AuthServiceWithHttp.ets` 中的方法复制到现有的 `AuthService.ets` 中

#### 使用示例：

```typescript
import { AuthServiceWithHttp } from '../viewmodel/AuthServiceWithHttp';

const authService = AuthServiceWithHttp.getInstance();
authService.setContext(context);

// 启用HTTP请求模式
authService.setUseHttp(true);

// 登录（会发送HTTP请求到后端）
const result = await authService.login('username', 'password', true);
```

## Java后端接口规范

### 登录接口

**请求：**
```
POST /api/auth/login
Content-Type: application/json

{
  "account": "username",
  "password": "password",
  "rememberMe": false
}
```

**响应：**
```json
{
  "code": 200,
  "data": {
    "id": "user123",
    "username": "username",
    "phone": "13800138000",
    "token": "jwt_token_here"
  },
  "message": "登录成功"
}
```

### 注册接口

**请求：**
```
POST /api/auth/register
Content-Type: application/json

{
  "username": "newuser",
  "phone": "13800138000",
  "password": "password123"
}
```

**响应：**
```json
{
  "code": 200,
  "data": {
    "id": "user456",
    "username": "newuser",
    "phone": "13800138000",
    "token": "jwt_token_here"
  },
  "message": "注册成功"
}
```

### 获取用户信息接口

**请求：**
```
GET /api/user/{userId}
Authorization: Bearer {token}
```

**响应：**
```json
{
  "code": 200,
  "data": {
    "id": "user123",
    "username": "username",
    "phone": "13800138000"
  },
  "message": "获取成功"
}
```

## 添加自定义API接口

在 `ApiService.ets` 中添加新的方法：

```typescript
/**
 * 自定义API示例
 */
async customApi(param1: string, param2: number): Promise<HttpResponse<any>> {
  try {
    const response = await httpUtil.post('/custom/endpoint', {
      param1: param1,
      param2: param2
    });
    return response;
  } catch (error) {
    logger.error('ApiService.customApi: 请求失败', error);
    throw error;
  }
}
```

## Token认证

HTTP工具类支持自动添加Token到请求头：

```typescript
import { httpUtil } from '../common/utils/HttpUtil';

// 设置Token（通常在登录成功后调用）
httpUtil.setAuthToken('your_jwt_token');

// 清除Token（在退出登录时调用）
httpUtil.clearAuthToken();
```

Token会自动添加到所有后续请求的 `Authorization` 头中：
```
Authorization: Bearer your_jwt_token
```

## 错误处理

HTTP工具类会自动处理常见错误：

- **网络超时**：返回"请求超时，请检查网络连接"
- **网络错误**：返回"网络连接失败，请检查网络设置"
- **其他错误**：返回具体的错误信息

使用示例：

```typescript
try {
  const response = await apiService.login({ account: 'user', password: 'pass' });
  if (response.code >= 200 && response.code < 300) {
    // 请求成功
    console.info('登录成功', response.data);
  } else {
    // 业务错误
    console.error('登录失败', response.message);
  }
} catch (error) {
  // 网络错误或其他异常
  console.error('请求异常', error);
}
```

## 注意事项

1. **修改BASE_URL**：务必在 `CommonConstant.ets` 中修改为你的实际后端地址
2. **HTTPS支持**：如果后端使用HTTPS，确保URL以 `https://` 开头
3. **跨域问题**：如果遇到跨域问题，需要在Java后端配置CORS
4. **网络权限**：已自动添加网络权限，无需额外配置
5. **超时设置**：默认超时时间为10秒，可在 `CommonConstant.ets` 中修改 `REQUEST_TIMEOUT`

## 测试建议

1. 先使用Postman等工具测试Java后端接口是否正常
2. 确认后端地址和端口是否正确
3. 检查后端返回的数据格式是否符合预期
4. 在HarmonyOS应用中测试HTTP请求功能

## 常见问题

### Q: 请求失败，提示网络错误
A: 检查：
- 后端服务是否启动
- BASE_URL是否正确
- 设备网络连接是否正常
- 防火墙是否阻止了连接

### Q: 返回401未授权
A: 检查：
- Token是否正确设置
- Token是否过期
- 后端是否需要Token认证

### Q: 请求超时
A: 可以：
- 增加 `REQUEST_TIMEOUT` 的值
- 检查网络连接速度
- 检查后端响应时间

## 更多帮助

如有问题，请查看：
- `HttpUtil.ets` - HTTP工具类源码
- `ApiService.ets` - API服务类源码
- `AuthServiceWithHttp.ets` - 使用HTTP的认证服务示例






















