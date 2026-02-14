# Chimera Flutter UI Automation 完整文档

## 目录

1. [简介](#简介)
2. [核心概念](#核心概念)
3. [安装与配置](#安装与配置)
4. [快速开始](#快速开始)
5. [API 参考](#api-参考)
6. [WebSocket 协议](#websocket-协议)
7. [高级用法](#高级用法)
8. [架构设计](#架构设计)
9. [常见问题](#常见问题)

---

## 简介

Chimera Flutter UI Automation 是一个专为 Flutter 应用设计的 UI 自动化库，支持：

- **远程控制**：通过 WebSocket 服务器实现 AI 远程操作
- **实时 UI 查询**：获取当前页面的所有元素信息
- **函数追踪**：追踪并执行点击的回调函数
- **行为录制**：记录用户的所有交互行为
- **自动回放**：AI 可以自动重现录制的行为
- **Release 兼容**：所有功能在生产环境下可用

### 特点

- ✅ 独立的 Flutter package，易于集成
- ✅ 内置 WebSocket 服务器（端口 59322）
- ✅ 基于 Flutter Semantics 系统
- ✅ 支持实时 UI 状态更新
- ✅ 页面识别功能
- ✅ 不需要鼠标轨迹，只追踪函数

---

## 核心概念

### 1. FunctionRegistry（函数注册表）

全局注册表，用于存储和管理所有可交互元素的回调函数。

```dart
// 注册函数
FunctionRegistry.register('button_id', FunctionInfo(...));

// 查询函数
FunctionInfo? info = FunctionRegistry.get('button_id');

// 注销函数
FunctionRegistry.unregister('button_id');
```

### 2. TrackedWidget（可追踪组件）

包装标准 Flutter 组件，自动注册和注销函数：

- `TrackedButton` - 可追踪的按钮
- `TrackedTextField` - 可追踪的文本框
- `TrackedGestureDetector` - 可追踪的手势检测器

### 3. UISnapshot（UI 快照）

捕获某一时刻的 UI 状态，包含：
- 时间戳
- 当前页面名称
- 所有可见元素列表
- 元素的位置、类型、动作等信息

### 4. RecordingSession（录制会话）

记录用户的一系列操作，包含：
- 会话 ID
- 开始/结束时间
- 所有用户动作列表
- 元数据

---

## 安装与配置

### 1. 添加依赖

在你的 Flutter 项目的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  chimera_flutter_ui_automation:
    path: ../chimera_flutter_ui_automation
```

### 2. 获取依赖

```bash
flutter pub get
```

### 3. 导入库

```dart
import 'package:chimera_flutter_ui_automation/chimera_flutter_ui_automation.dart';
```

---

## 快速开始

### 步骤 1：初始化库

在 `main.dart` 中初始化自动化库：

```dart
import 'package:flutter/material.dart';
import 'package:chimera_flutter_ui_automation/chimera_flutter_ui_automation.dart';

void main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化自动化库
  await AutomationController.initialize(
    port: 59322,              // WebSocket 端口
    enableRecording: true,    // 启用录制功能
  );

  runApp(const MyApp());
}
```

### 步骤 2：使用 TrackedWidget

将标准组件替换为可追踪版本：

```dart
class LoginPage extends StatelessWidget {
  void handleLogin() {
    print('执行登录');
    // 登录逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 使用 TrackedTextField
          TrackedTextField(
            identifier: 'username_field',      // 唯一标识符
            functionName: 'onUsernameChanged', // 函数名称（用于日志）
            onChanged: (value) {
              print('用户名: $value');
            },
            decoration: InputDecoration(
              labelText: '用户名',
            ),
          ),

          // 使用 TrackedButton
          TrackedButton(
            identifier: 'login_button',
            functionName: 'handleLogin',
            onPressed: handleLogin,
            child: Text('登录'),
          ),
        ],
      ),
    );
  }
}
```

### 步骤 3：通过 WebSocket 控制

使用任何支持 WebSocket 的客户端连接到 `ws://localhost:59322`：

```python
import asyncio
import websockets
import json

async def get_ui():
    uri = "ws://localhost:59322"
    async with websockets.connect(uri) as ws:
        # 获取 UI 状态
        await ws.send(json.dumps({
            "command": "getUI",
            "params": {}
        }))
        response = await ws.recv()
        print(json.loads(response))

asyncio.run(get_ui())
```

---

## API 参考

### AutomationController

主控制器，提供初始化和管理功能。

#### 方法

##### `initialize()`

初始化自动化库。

```dart
static Future<void> initialize({
  int port = 59322,           // WebSocket 端口
  bool enableRecording = true, // 是否启用录制
  BuildContext? context,       // 可选的上下文
})
```

##### `shutdown()`

关闭自动化库。

```dart
static Future<void> shutdown()
```

##### `captureUI()`

捕获当前 UI 状态。

```dart
static UISnapshot captureUI(BuildContext? context)
```

##### 属性

- `isInitialized` - 是否已初始化
- `server` - WebSocket 服务器实例
- `recorder` - 行为录制器实例
- `replayEngine` - 回放引擎实例

### TrackedButton

可追踪的按钮组件。

```dart
TrackedButton({
  required String identifier,      // 唯一标识符
  String? functionName,            // 函数名称
  required VoidCallback? onPressed, // 点击回调
  required Widget child,           // 子组件
  Map<String, dynamic>? metadata,  // 元数据
  ButtonStyle? style,              // 按钮样式
})
```

### TrackedTextField

可追踪的文本框组件。

```dart
TrackedTextField({
  required String identifier,           // 唯一标识符
  String? functionName,                 // 函数名称
  ValueChanged<String>? onChanged,      // 文本改变回调
  ValueChanged<String>? onSubmitted,    // 提交回调
  TextEditingController? controller,    // 文本控制器
  InputDecoration? decoration,          // 装饰
  Map<String, dynamic>? metadata,       // 元数据
})
```

### TrackedGestureDetector

可追踪的手势检测器。

```dart
TrackedGestureDetector({
  required String identifier,              // 唯一标识符
  String? functionName,                    // 函数名称
  GestureTapCallback? onTap,              // 点击回调
  GestureLongPressCallback? onLongPress,  // 长按回调
  GestureTapCallback? onDoubleTap,        // 双击回调
  required Widget child,                   // 子组件
  Map<String, dynamic>? metadata,          // 元数据
})
```

### FunctionRegistry

全局函数注册表。

```dart
// 注册函数
static void register(String identifier, FunctionInfo info)

// 获取函数
static FunctionInfo? get(String identifier)

// 注销函数
static void unregister(String identifier)

// 获取所有函数
static List<FunctionInfo> getAll()

// 检查是否存在
static bool contains(String identifier)

// 清空注册表
static void clear()
```

### BehaviorRecorder

行为录制器。

```dart
// 开始录制
void startRecording({
  required String sessionId,
  bool captureUIState = false,
  Map<String, dynamic>? metadata,
})

// 停止录制
RecordingSession? stopRecording()

// 检查是否正在录制
bool get isRecording

// 手动记录动作
void recordAction({
  required String actionType,
  required String targetIdentifier,
  required String targetLabel,
  String? functionName,
  String? functionId,
  dynamic arguments,
  UISnapshot? uiStateBefore,
})
```

### ReplayEngine

回放引擎。

```dart
// 回放会话
Future<ReplayResult> replay(RecordingSession session)
```

---

## WebSocket 协议

### 连接

连接到 `ws://localhost:59322`

### 请求格式

```json
{
  "command": "命令名称",
  "params": {
    // 参数
  }
}
```

### 响应格式

```json
{
  "success": true/false,
  "data": {
    // 数据
  },
  "message": "消息",
  "error": "错误信息"
}
```

### 支持的命令

#### 1. getUI - 获取 UI 状态

**请求：**
```json
{
  "command": "getUI",
  "params": {
    "includeHidden": false,
    "includeFunctions": true
  }
}
```

**响应：**
```json
{
  "success": true,
  "data": {
    "timestamp": "2024-01-01T10:00:00Z",
    "currentPage": "HomePage",
    "elements": [
      {
        "identifier": "login_button",
        "label": "登录",
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

#### 3. input - 输入文本

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

#### 4. startRecord - 开始录制

**请求：**
```json
{
  "command": "startRecord",
  "params": {
    "sessionId": "session_001",
    "captureUIState": true
  }
}
```

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

#### 5. stopRecord - 停止录制

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
    "startTime": "2024-01-01T10:00:00Z",
    "endTime": "2024-01-01T10:05:00Z",
    "actions": [
      {
        "timestamp": "2024-01-01T10:01:00Z",
        "actionType": "tap",
        "targetIdentifier": "login_button",
        "targetLabel": "登录",
        "functionName": "handleLogin"
      }
    ]
  },
  "message": "Recording stopped"
}
```

#### 6. replay - 回放录制

**请求：**
```json
{
  "command": "replay",
  "params": {
    "session": {
      "sessionId": "session_001",
      "actions": [...]
    }
  }
}
```

**响应：**
```json
{
  "success": true,
  "data": {
    "success": true,
    "totalActions": 10,
    "successfulActions": 10,
    "errors": []
  }
}
```

---

## 高级用法

### 1. 自定义元数据

为 TrackedWidget 添加自定义元数据：

```dart
TrackedButton(
  identifier: 'submit_button',
  functionName: 'handleSubmit',
  onPressed: handleSubmit,
  metadata: {
    'page': 'checkout',
    'step': 3,
    'critical': true,
  },
  child: Text('提交订单'),
)
```

### 2. 手动记录动作

在不使用 TrackedWidget 的情况下手动记录：

```dart
BehaviorRecorder().recordAction(
  actionType: 'custom_action',
  targetIdentifier: 'custom_element',
  targetLabel: '自定义元素',
  functionName: 'customFunction',
  arguments: {'key': 'value'},
);
```

### 3. 条件录制

只在特定条件下录制：

```dart
void handleImportantAction() {
  if (shouldRecord) {
    BehaviorRecorder().recordAction(
      actionType: 'important_action',
      targetIdentifier: 'important_button',
      targetLabel: '重要按钮',
    );
  }
  // 执行实际逻辑
}
```

### 4. 自定义回放逻辑

```dart
final session = recorder.stopRecording();
if (session != null) {
  // 过滤某些动作
  final filteredActions = session.actions.where(
    (action) => action.actionType != 'debug_action'
  ).toList();

  final filteredSession = RecordingSession(
    sessionId: session.sessionId,
    startTime: session.startTime,
    endTime: session.endTime,
    actions: filteredActions,
  );

  // 回放过滤后的会话
  final result = await ReplayEngine().replay(filteredSession);
}
```

---

## 架构设计

### 整体架构

```
┌─────────────────────────────────────────────┐
│          AI 客户端 (Python/Node.js)          │
│  - 发送命令                                  │
│  - 接收 UI 状态                              │
│  - 分析和决策                                │
└─────────────────────────────────────────────┘
                    ↓ WebSocket (59322)
┌─────────────────────────────────────────────┐
│     chimera_flutter_ui_automation 库         │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │      WebSocket 服务器                  │ │
│  │  - 监听端口 59322                      │ │
│  │  - 处理连接                            │ │
│  │  - 消息路由                            │ │
│  └───────────────────────────────────────┘ │
│                    ↓                        │
│  ┌───────────────────────────────────────┐ │
│  │      命令处理器 (CommandHandler)       │ │
│  │  - 解析 JSON 命令                      │ │
│  │  - 调用相应功能                        │ │
│  │  - 格式化响应                          │ │
│  └───────────────────────────────────────┘ │
│                    ↓                        │
│  ┌───────────────────────────────────────┐ │
│  │         核心功能模块                   │ │
│  │                                       │ │
│  │  • FunctionRegistry - 函数注册表      │ │
│  │  • UIStateCapture - UI 状态捕获      │ │
│  │  • BehaviorRecorder - 行为录制器     │ │
│  │  • ReplayEngine - 回放引擎           │ │
│  └───────────────────────────────────────┘ │
│                    ↓                        │
│  ┌───────────────────────────────────────┐ │
│  │      TrackedWidget 包装器              │ │
│  │  - TrackedButton                      │ │
│  │  - TrackedTextField                   │ │
│  │  - TrackedGestureDetector             │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│           你的 Flutter 应用                  │
│  - 使用 TrackedWidget                       │
│  - 初始化 AutomationController              │
└─────────────────────────────────────────────┘
```

### 数据流

#### 1. UI 查询流程

```
AI 客户端 → WebSocket → CommandHandler → UIStateCapture
                                              ↓
                                    遍历 Semantics Tree
                                              ↓
                                    查询 FunctionRegistry
                                              ↓
                                    构建 UISnapshot
                                              ↓
AI 客户端 ← WebSocket ← CommandHandler ← UISnapshot
```

#### 2. 点击执行流程

```
AI 客户端 → WebSocket → CommandHandler
                              ↓
                    查询 FunctionRegistry
                              ↓
                    获取 FunctionInfo
                              ↓
                    执行回调函数
                              ↓
AI 客户端 ← WebSocket ← 返回结果
```

#### 3. 录制流程

```
用户操作 → TrackedWidget → 触发回调
                              ↓
                    BehaviorRecorder.recordAction()
                              ↓
                    添加到 actions 列表
                              ↓
                    存储在 RecordingSession
```

### 关键设计决策

#### 1. 为什么使用 FunctionRegistry？

Flutter 的 Semantics 系统不暴露回调函数（`_actions` 是私有的），因此我们需要一个平行的系统来追踪函数。FunctionRegistry 提供了：

- 全局访问点
- 生命周期管理（自动注册/注销）
- 元数据支持

#### 2. 为什么使用 TrackedWidget？

TrackedWidget 模式提供了：

- 自动化的函数注册/注销
- 与 Semantics 系统的集成
- 最小的代码侵入性
- 清晰的 API

#### 3. 为什么选择 WebSocket？

WebSocket 提供了：

- 双向通信
- 低延迟
- 实时更新
- 广泛的客户端支持

---

## 常见问题

### Q1: 为什么在 Release 模式下也能工作？

A: 我们使用的所有 API（Semantics、WebSocket、函数引用）在 Release 模式下都是可用的。只需要显式启用 Semantics：

```dart
WidgetsBinding.instance.ensureSemantics();
```

### Q2: 如何确保 identifier 的唯一性？

A: 建议使用命名约定，例如：

```dart
'${pageName}_${widgetType}_${purpose}'
// 例如：'login_button_submit'
```

### Q3: TrackedWidget 会影响性能吗？

A: 影响很小。TrackedWidget 只是在 initState 和 dispose 时操作注册表，不会影响渲染性能。

### Q4: 可以在现有项目中逐步集成吗？

A: 可以。你可以先在关键页面使用 TrackedWidget，逐步扩展到整个应用。

### Q5: 如何调试 WebSocket 连接？

A: 使用浏览器开发者工具或专门的 WebSocket 客户端（如 Postman）进行测试。

### Q6: 录制的数据可以持久化吗？

A: 可以。RecordingSession 可以序列化为 JSON：

```dart
final session = recorder.stopRecording();
final json = session.toJson();
// 保存到文件或数据库
```

### Q7: 如何处理动态生成的 Widget？

A: 确保每个动态 Widget 都有唯一的 identifier，可以使用索引或 ID：

```dart
ListView.builder(
  itemBuilder: (context, index) {
    return TrackedButton(
      identifier: 'list_item_$index',
      // ...
    );
  },
)
```

### Q8: 安全性如何保证？

A: 建议：

1. 只在开发/测试环境启用
2. 使用环境变量控制
3. 添加认证机制
4. 不要暴露到公网

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 只在调试模式启用
  if (kDebugMode) {
    await AutomationController.initialize(port: 59322);
  }

  runApp(MyApp());
}
```

### Q9: 如何获取当前页面名称？

A: 库会自动尝试获取，但你也可以手动设置：

```dart
MaterialPageRoute(
  settings: RouteSettings(name: 'LoginPage'),
  builder: (context) => LoginPage(),
)
```

### Q10: 可以追踪哪些类型的操作？

A: 目前支持：

- 按钮点击（tap）
- 长按（longPress）
- 双击（doubleTap）
- 文本输入（setText）
- 滚动（scroll）

---

## 示例代码

### 完整示例：登录页面

```dart
import 'package:flutter/material.dart';
import 'package:chimera_flutter_ui_automation/chimera_flutter_ui_automation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    // 模拟登录
    await Future.delayed(Duration(seconds: 2));

    setState(() => _isLoading = false);

    // 导航到主页
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登录')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TrackedTextField(
              identifier: 'login_username_field',
              functionName: 'onUsernameChanged',
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                print('用户名输入: $value');
              },
            ),
            SizedBox(height: 16),
            TrackedTextField(
              identifier: 'login_password_field',
              functionName: 'onPasswordChanged',
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                print('密码输入: $value');
              },
            ),
            SizedBox(height: 24),
            TrackedButton(
              identifier: 'login_submit_button',
              functionName: 'handleLogin',
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('登录'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

### Python 客户端完整示例

```python
import asyncio
import websockets
import json

class ChimeraClient:
    def __init__(self, uri="ws://localhost:59322"):
        self.uri = uri

    async def connect(self):
        self.ws = await websockets.connect(self.uri)
        print(f"已连接到 {self.uri}")

    async def send_command(self, command, params=None):
        request = {
            "command": command,
            "params": params or {}
        }
        await self.ws.send(json.dumps(request))
        response = await self.ws.recv()
        return json.loads(response)

    async def get_ui(self):
        """获取当前 UI 状态"""
        return await self.send_command("getUI")

    async def tap(self, identifier):
        """点击元素"""
        return await self.send_command("tap", {"identifier": identifier})

    async def input_text(self, identifier, text):
        """输入文本"""
        return await self.send_command("input", {
            "identifier": identifier,
            "text": text
        })

    async def start_recording(self, session_id):
        """开始录制"""
        return await self.send_command("startRecord", {
            "sessionId": session_id
        })

    async def stop_recording(self):
        """停止录制"""
        return await self.send_command("stopRecord")

    async def replay(self, session):
        """回放会话"""
        return await self.send_command("replay", {"session": session})

    async def close(self):
        await self.ws.close()

# 使用示例
async def main():
    client = ChimeraClient()
    await client.connect()

    try:
        # 1. 获取 UI 状态
        ui = await client.get_ui()
        print("当前页面:", ui['data']['currentPage'])
        print("元素列表:")
        for element in ui['data']['elements']:
            print(f"  - {element['label']} ({element['identifier']})")

        # 2. 输入用户名
        await client.input_text('login_username_field', 'admin')

        # 3. 输入密码
        await client.input_text('login_password_field', 'password123')

        # 4. 点击登录按钮
        result = await client.tap('login_submit_button')
        print("登录结果:", result)

    finally:
        await client.close()

if __name__ == "__main__":
    asyncio.run(main())
```

---

## 总结

Chimera Flutter UI Automation 提供了一套完整的 UI 自动化解决方案，适用于：

- **AI 驱动的测试**：让 AI 自动测试你的应用
- **行为分析**：记录和分析用户行为
- **自动化演示**：自动演示应用功能
- **回归测试**：录制测试场景并自动回放

通过简单的 API 和最小的代码侵入，你可以快速为 Flutter 应用添加强大的自动化能力。
