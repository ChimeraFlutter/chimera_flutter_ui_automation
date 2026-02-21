# Chimera Flutter UI Automation - 协议文档

本文档详细说明 WebSocket 和 MCP (Model Context Protocol) 两种协议的规范和使用方法。

## 目录

- [概述](#概述)
- [WebSocket 协议](#websocket-协议)
- [MCP 协议](#mcp-协议)
- [功能对比](#功能对比)
- [使用示例](#使用示例)

---

## 概述

Chimera Flutter UI Automation 提供两种协议接口：

| 协议 | 端口 | 用途 | 客户端 |
|------|------|------|--------|
| **WebSocket** | 59322 | 通用自动化接口 | Python, JavaScript, Go 等任何支持 WebSocket 的语言 |
| **MCP** | 59323 | Claude Code 集成 | Claude Code CLI |

**选择建议：**
- 如果你想用 Python/JS 编写自动化脚本 → 使用 **WebSocket**
- 如果你想让 Claude AI 直接操作应用 → 使用 **MCP**

---

## WebSocket 协议

### 连接信息

- **URL**: `ws://localhost:59322`
- **协议**: WebSocket (RFC 6455)
- **数据格式**: JSON

### 请求格式

```json
{
  "command": "命令名称",
  "params": {
    "参数名": "参数值"
  }
}
```

### 响应格式

```json
{
  "success": true,
  "data": { /* 返回数据 */ },
  "message": "操作成功"
}
```

或错误响应：

```json
{
  "success": false,
  "message": "错误信息"
}
```

### 支持的命令

#### 1. getUI - 获取 UI 状态

获取当前界面的所有元素信息。

**请求：**
```json
{
  "command": "getUI",
  "params": {}
}
```

**响应：**
```json
{
  "success": true,
  "data": {
    "timestamp": "2026-02-20T10:00:00.000Z",
    "currentPage": "HomePage",
    "elements": [
      {
        "identifier": "login_button",
        "label": "Login",
        "type": "button",
        "rect": {"x": 100, "y": 200, "width": 80, "height": 40},
        "actions": ["tap"],
        "functionName": "handleLogin",
        "visible": true
      }
    ]
  }
}
```

#### 2. tap - 点击元素

通过 identifier 点击指定元素。

**请求：**
```json
{
  "command": "tap",
  "params": {
    "identifier": "login_button"
  }
}
```

**响应：**
```json
{
  "success": true,
  "message": "Tapped on login_button"
}
```

**错误：**
```json
{
  "success": false,
  "message": "Element not found: login_button"
}
```

#### 3. input - 输入文本

在文本框中输入内容。

**请求：**
```json
{
  "command": "input",
  "params": {
    "identifier": "username_field",
    "text": "admin"
  }
}
```

**响应：**
```json
{
  "success": true,
  "message": "Input text to username_field"
}
```

#### 4. screenshot - 截图

捕获当前应用窗口的截图。

**请求：**
```json
{
  "command": "screenshot",
  "params": {
    "pixelRatio": 1.0,
    "includeMetadata": true,
    "maxRecentActions": 10
  }
}
```

**参数说明：**
- `pixelRatio` (可选, 默认 1.0): 图像分辨率倍数 (0 < x ≤ 3.0)
- `includeMetadata` (可选, 默认 true): 是否包含元数据
- `maxRecentActions` (可选, 默认 10): 包含的最近操作数量

**响应：**
```json
{
  "success": true,
  "data": {
    "base64Image": "iVBORw0KGgoAAAANSUhEUgAA...",
    "mimeType": "image/png",
    "width": 800,
    "height": 600,
    "timestamp": "2026-02-20T10:30:45.123Z",
    "metadata": {
      "currentRoute": "HomePage",
      "uiSnapshot": { /* UI 元素信息 */ },
      "recentActions": [
        {
          "type": "tap",
          "identifier": "increment_button",
          "timestamp": "2026-02-20T10:30:40.000Z"
        }
      ],
      "windowInfo": {
        "width": 800,
        "height": 600
      }
    }
  },
  "message": "Screenshot captured successfully"
}
```

**限流：**
- 最多 1 次/秒（可通过 `screenshotRateLimitMs` 配置）
- 超过限制返回错误：
```json
{
  "success": false,
  "message": "Screenshot failed: Rate limit exceeded. Please wait..."
}
```

#### 5. startRecord - 开始录制

开始录制用户操作。

**请求：**
```json
{
  "command": "startRecord",
  "params": {
    "sessionId": "session_001",
    "captureUIState": false
  }
}
```

**参数说明：**
- `sessionId` (可选): 会话 ID，不提供则自动生成
- `captureUIState` (可选, 默认 false): 是否捕获每次操作时的 UI 状态

**响应：**
```json
{
  "success": true,
  "data": {
    "sessionId": "session_001"
  },
  "message": "Recording started"
}
```

#### 6. stopRecord - 停止录制

停止录制并返回录制的操作序列。

**请求：**
```json
{
  "command": "stopRecord"
}
```

**响应：**
```json
{
  "success": true,
  "data": {
    "sessionId": "session_001",
    "startTime": "2026-02-20T10:00:00.000Z",
    "endTime": "2026-02-20T10:05:00.000Z",
    "actions": [
      {
        "type": "tap",
        "identifier": "login_button",
        "timestamp": "2026-02-20T10:00:05.000Z"
      },
      {
        "type": "input",
        "identifier": "username_field",
        "text": "admin",
        "timestamp": "2026-02-20T10:00:10.000Z"
      }
    ]
  },
  "message": "Recording stopped"
}
```

#### 7. replay - 回放录制

回放之前录制的操作序列。

**请求：**
```json
{
  "command": "replay",
  "params": {
    "session": {
      "sessionId": "session_001",
      "actions": [
        {
          "type": "tap",
          "identifier": "login_button",
          "timestamp": "2026-02-20T10:00:05.000Z"
        }
      ]
    }
  }
}
```

**响应：**
```json
{
  "success": true,
  "data": {
    "totalActions": 5,
    "successfulActions": 5,
    "failedActions": 0,
    "duration": 2500
  }
}
```

---

## MCP 协议

### 连接信息

- **URL**: `http://127.0.0.1:59323/mcp`
- **协议**: HTTP (JSON-RPC 2.0)
- **传输**: Model Context Protocol

### 配置方法

```bash
# 添加 MCP server 到 Claude Code
claude mcp add --transport http chimera_flutter_ui http://127.0.0.1:59323/mcp

# 验证配置
claude mcp list
```

### 支持的工具

#### UI 操作工具

| 工具名 | 描述 | 对应 WebSocket 命令 |
|--------|------|---------------------|
| `ui.snapshot` | 获取当前 UI 状态 | `getUI` |
| `ui.tap` | 通过 ID 点击元素 | `tap` |
| `ui.tap_by_label` | 通过文本标签点击元素 | ❌ (WebSocket 不支持) |
| `ui.input_text` | 输入文本 | `input` |
| `ui.scroll` | 滚动界面 | ❌ (WebSocket 不支持) |
| `ui.get_screen` | 获取当前页面名 | ❌ (WebSocket 不支持) |
| `ui.capture_screen` | 截图 | `screenshot` |
| `ui.start_recording` | 开始录制 | `startRecord` |
| `ui.stop_recording` | 停止录制 | `stopRecord` |

#### 开发工具

| 工具名 | 描述 |
|--------|------|
| `dev.hot_reload` | 触发 Flutter Hot Reload (r) |
| `dev.hot_restart` | 触发 Flutter Hot Restart (R) |
| `dev.vm_info` | 获取 Dart VM 信息 |

### 使用方法

在 Claude Code 中直接用自然语言对话：

```
你: 请查看当前界面

Claude: [自动调用 ui.snapshot]
当前界面是 HomePage，包含以下元素：
- "Login" 按钮
- "Username" 文本框
- "Password" 文本框

你: 请点击 Login 按钮

Claude: [自动调用 ui.tap_by_label]
✅ 已点击 "Login" 按钮

你: 请截图

Claude: [自动调用 ui.capture_screen]
[显示截图]
截图尺寸: 800x600
当前页面: HomePage
```

---

## 功能对比

### 完整功能对比表

| 功能 | WebSocket | MCP | 说明 |
|------|-----------|-----|------|
| **UI 查询** |
| 获取 UI 状态 | ✅ `getUI` | ✅ `ui.snapshot` | 获取所有元素信息 |
| 获取当前页面名 | ❌ | ✅ `ui.get_screen` | MCP 独有 |
| **UI 操作** |
| 通过 ID 点击 | ✅ `tap` | ✅ `ui.tap` | 需要知道 identifier |
| 通过文本点击 | ❌ | ✅ `ui.tap_by_label` | MCP 独有，更方便 |
| 输入文本 | ✅ `input` | ✅ `ui.input_text` | 功能相同 |
| 滚动 | ❌ | ✅ `ui.scroll` | MCP 独有 |
| **截图** |
| 截图 | ✅ `screenshot` | ✅ `ui.capture_screen` | 功能相同 |
| **录制回放** |
| 开始录制 | ✅ `startRecord` | ✅ `ui.start_recording` | 功能相同 |
| 停止录制 | ✅ `stopRecord` | ✅ `ui.stop_recording` | 功能相同 |
| 回放 | ✅ `replay` | ❌ | WebSocket 独有 |
| **开发工具** |
| Hot Reload | ❌ | ✅ `dev.hot_reload` | MCP 独有 |
| Hot Restart | ❌ | ✅ `dev.hot_restart` | MCP 独有 |
| VM 信息 | ❌ | ✅ `dev.vm_info` | MCP 独有 |

### 协议特点对比

| 特性 | WebSocket | MCP |
|------|-----------|-----|
| **连接方式** | 直接连接 | 通过 Claude Code CLI |
| **客户端** | 任何语言 | 仅 Claude Code |
| **使用方式** | 编程调用 | 自然语言对话 |
| **实时性** | 长连接，实时 | HTTP 请求，按需 |
| **适用场景** | 自动化脚本、测试 | AI 辅助开发 |
| **学习成本** | 需要了解 API | 自然语言即可 |

---

## 使用示例

### WebSocket 示例 (Python)

```python
import asyncio
import websockets
import json
import base64

async def main():
    uri = "ws://localhost:59322"

    async with websockets.connect(uri) as websocket:
        # 1. 获取 UI 状态
        await websocket.send(json.dumps({
            "command": "getUI",
            "params": {}
        }))
        response = json.loads(await websocket.recv())
        print(f"当前页面: {response['data']['currentPage']}")

        # 2. 点击按钮
        await websocket.send(json.dumps({
            "command": "tap",
            "params": {"identifier": "login_button"}
        }))
        response = json.loads(await websocket.recv())
        print(f"点击结果: {response['message']}")

        # 3. 输入文本
        await websocket.send(json.dumps({
            "command": "input",
            "params": {
                "identifier": "username_field",
                "text": "admin"
            }
        }))
        response = json.loads(await websocket.recv())
        print(f"输入结果: {response['message']}")

        # 4. 截图
        await websocket.send(json.dumps({
            "command": "screenshot",
            "params": {
                "pixelRatio": 1.0,
                "includeMetadata": True
            }
        }))
        response = json.loads(await websocket.recv())

        if response['success']:
            # 保存截图
            img_data = base64.b64decode(response['data']['base64Image'])
            with open('screenshot.png', 'wb') as f:
                f.write(img_data)
            print(f"截图已保存: {response['data']['width']}x{response['data']['height']}")

        # 5. 录制和回放
        # 开始录制
        await websocket.send(json.dumps({
            "command": "startRecord",
            "params": {"sessionId": "test_session"}
        }))
        await websocket.recv()

        # 执行一些操作...
        await websocket.send(json.dumps({
            "command": "tap",
            "params": {"identifier": "button1"}
        }))
        await websocket.recv()

        # 停止录制
        await websocket.send(json.dumps({
            "command": "stopRecord"
        }))
        session_response = json.loads(await websocket.recv())
        session = session_response['data']

        # 回放
        await websocket.send(json.dumps({
            "command": "replay",
            "params": {"session": session}
        }))
        replay_response = json.loads(await websocket.recv())
        print(f"回放完成: {replay_response['data']}")

asyncio.run(main())
```

### WebSocket 示例 (JavaScript)

```javascript
const WebSocket = require('ws');

async function main() {
    const ws = new WebSocket('ws://localhost:59322');

    ws.on('open', async () => {
        // 获取 UI 状态
        ws.send(JSON.stringify({
            command: 'getUI',
            params: {}
        }));
    });

    ws.on('message', (data) => {
        const response = JSON.parse(data);
        console.log('响应:', response);

        if (response.success) {
            // 处理成功响应
            if (response.data.currentPage) {
                console.log('当前页面:', response.data.currentPage);
            }
        } else {
            console.error('错误:', response.message);
        }
    });
}

main();
```

### MCP 示例 (Claude Code)

```bash
# 启动 Claude Code
claude

# 然后直接对话：
```

**示例对话 1：查看和操作 UI**
```
你: 请查看当前界面有哪些按钮

Claude: [调用 ui.snapshot]
当前界面有以下按钮：
1. "登录" 按钮 (identifier: login_button)
2. "注册" 按钮 (identifier: register_button)
3. "忘记密码" 链接 (identifier: forgot_password)

你: 点击登录按钮

Claude: [调用 ui.tap_by_label with "登录"]
✅ 已点击 "登录" 按钮
```

**示例对话 2：截图和分析**
```
你: 请截图当前界面并分析

Claude: [调用 ui.capture_screen]
[显示截图]

当前界面分析：
- 页面: LoginPage
- 尺寸: 800x600
- 主要元素:
  - 用户名输入框
  - 密码输入框
  - 登录按钮
  - 注册链接
- 最近操作: 无

界面设计简洁，符合标准登录页面布局。
```

**示例对话 3：开发工具**
```
你: 我修改了代码，请执行 Hot Reload

Claude: [调用 dev.hot_reload]
✅ Hot Reload 成功执行

你: 查看一下 VM 信息

Claude: [调用 dev.vm_info]
Dart VM 信息：
- 版本: 3.11.0
- 模式: Debug
- 内存使用: 128 MB
- 隔离区数量: 2
```

---

## 错误处理

### WebSocket 错误

所有错误响应格式：
```json
{
  "success": false,
  "message": "错误描述"
}
```

常见错误：
- `Invalid message format` - JSON 格式错误
- `Unknown command` - 不支持的命令
- `Missing parameter` - 缺少必需参数
- `Element not found` - 元素不存在
- `Rate limit exceeded` - 超过限流限制

### MCP 错误

MCP 错误通过 JSON-RPC 2.0 错误格式返回：
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32000,
    "message": "错误描述",
    "data": { /* 额外信息 */ }
  }
}
```

---

## 安全注意事项

1. **仅本地访问**
   - WebSocket 和 MCP 都只监听 `localhost`
   - 不接受来自其他机器的连接

2. **开发环境使用**
   - 这些接口仅用于开发和测试
   - 不要在生产环境启用

3. **限流保护**
   - 截图功能有限流保护（默认 1 次/秒）
   - 防止资源滥用

4. **无身份验证**
   - 当前版本不需要身份验证
   - 依赖本地访问限制

---

## 配置参数

### 初始化配置

```dart
await AutomationController.initialize(
  // WebSocket 配置
  port: 59322,                    // WebSocket 端口

  // MCP 配置
  enableMCP: true,                // 是否启用 MCP
  mcpPort: 59323,                 // MCP 端口

  // 功能配置
  enableRecording: true,          // 是否启用录制
  enableScreenshot: true,         // 是否启用截图
  screenshotRateLimitMs: 1000,   // 截图限流（毫秒）

  // 上下文
  context: context,               // BuildContext（可选）
);
```

---

## 版本信息

- **协议版本**: 1.0
- **最后更新**: 2026-02-20
- **兼容性**: Flutter 3.0+

---

## 相关文档

- [README.md](README.md) - 项目概述和快速开始
- [MCP_IMPLEMENTATION.md](MCP_IMPLEMENTATION.md) - MCP 实现细节

---

## 支持

如有问题或建议，请提交 Issue 到项目仓库。
