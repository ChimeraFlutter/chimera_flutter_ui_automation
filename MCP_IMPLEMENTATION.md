# Chimera Flutter UI Automation - MCP 集成完成

## 实现概述

已成功在 `chimera_flutter_ui_automation` 包中实现了 MCP (Model Context Protocol) 支持，并集成到 `flutter_hello` 项目中。

## 实现的功能

### 1. MCP HTTP Server
- **文件**: `/Users/acewill/chimera_flutter_ui_automation/lib/src/server/mcp_server.dart`
- **端口**: 59323 (默认)
- **协议**: JSON-RPC 2.0 over HTTP
- **安全**: 仅监听 localhost + Token 认证 + Origin 校验

### 2. MCP Tools (工具列表)

#### UI 操作工具
- `ui.snapshot` - 获取当前界面的完整描述（纯文本格式）
- `ui.tap` - 通过元素 ID 点击
- `ui.tap_by_label` - 通过标签文本点击（支持模糊匹配）
- `ui.input_text` - 在文本框中输入文本
- `ui.scroll` - 滚动界面
- `ui.get_screen` - 获取当前屏幕名称

#### 录制回放工具
- `ui.start_recording` - 开始录制用户操作
- `ui.stop_recording` - 停止录制

#### 开发工具
- `dev.hot_reload` - 执行 Flutter Hot Reload (r)
- `dev.hot_restart` - 执行 Flutter Hot Restart (R)
- `dev.vm_info` - 获取 Dart VM 信息

### 3. VM Service 集成
- **文件**: `/Users/acewill/chimera_flutter_ui_automation/lib/src/core/vm_service_integration.dart`
- **功能**:
  - 通过 `dart:developer` 获取 VM Service URI
  - 连接到 VM Service
  - 执行 Hot Reload (`reloadSources`)
  - 执行 Hot Restart (`ext.flutter.hotRestart`)

### 4. 依赖更新
- 添加了 `vm_service: ^14.2.5` 依赖

## 使用方法

### 1. 启动 Flutter 应用

```bash
cd /Users/acewill/flutter_hello
flutter run
```

应用启动后会在控制台输出：
```
Chimera UI Automation 已启动
  - WebSocket 端口: 59322
  - MCP 端口: 59323
  - 使用 Claude Code 连接: claude mcp add --transport http chimera_flutter_ui http://127.0.0.1:59323/mcp
```

### 2. 连接 Claude Code

```bash
# 添加 MCP server
claude mcp add --transport http chimera_flutter_ui http://127.0.0.1:59323/mcp

# Token 会在应用启动时打印在控制台
# 格式: chimera_<timestamp>
```

### 3. 在 Claude Code 中使用

```
用户: 请查看当前 Flutter 应用的界面
Claude: [调用 ui.snapshot 工具]
Screen: HomePage
---
[1] Button "进入性能测试页面" - tappable
[2] Button "Wrap 组件示例" - tappable
...

用户: 请点击性能测试按钮
Claude: [调用 ui.tap_by_label 工具]
成功点击元素: 进入性能测试页面

用户: 执行 Hot Reload
Claude: [调用 dev.hot_reload 工具]
✅ Hot Reload 成功执行
```

## 架构说明

```
flutter_hello (应用)
    ↓ 依赖
chimera_flutter_ui_automation (包)
    ↓ 包含
├─ WebSocket Server (端口 59322)
├─ MCP HTTP Server (端口 59323)
│   ├─ UI 操作工具
│   ├─ 录制回放工具
│   └─ 开发工具 (Hot Reload/Restart)
├─ VM Service Integration
├─ UI State Capture (Semantics)
├─ Function Registry
└─ Behavior Recorder
```

## 关键文件

### chimera_flutter_ui_automation 包
1. `lib/src/server/mcp_server.dart` - MCP HTTP Server 实现
2. `lib/src/core/vm_service_integration.dart` - VM Service 集成
3. `lib/automation_controller.dart` - 主控制器
4. `pubspec.yaml` - 添加了 vm_service 依赖

### flutter_hello 应用
1. `lib/main.dart` - 初始化 MCP 系统
2. `pubspec.yaml` - 引用 chimera_flutter_ui_automation 包

## 测试方法

### 1. 手动测试 MCP 端点

```bash
# 获取工具列表
curl -X POST http://localhost:59323/mcp \
  -H "Content-Type: application/json" \
  -H "X-MCP-Token: <your-token>" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'

# 调用 ui.snapshot
curl -X POST http://localhost:59323/mcp \
  -H "Content-Type: application/json" \
  -H "X-MCP-Token: <your-token>" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "ui.snapshot",
      "arguments": {}
    }
  }'
```

### 2. 测试 Hot Reload

```bash
# 修改代码后调用
curl -X POST http://localhost:59323/mcp \
  -H "Content-Type: application/json" \
  -H "X-MCP-Token: <your-token>" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "dev.hot_reload",
      "arguments": {}
    }
  }'
```

## 注意事项

1. **Release 模式限制**: Hot Reload/Restart 功能仅在 Debug 和 Profile 模式下可用，Release 模式下 VM Service 不可用
2. **安全性**: MCP Server 仅监听 localhost，使用 Token 认证，并验证 Origin header
3. **端口冲突**: 确保端口 59322 (WebSocket) 和 59323 (MCP) 未被占用
4. **Token**: 每次应用启动会生成新的 Token，需要在控制台查看

## 下一步

可以考虑的扩展功能：
1. 添加截图功能 (结合 UI 描述)
2. 支持更复杂的手势操作
3. 添加性能监控工具
4. 支持多个 Flutter 应用同时连接
5. 添加 WebSocket 推送 UI 变化通知

## 参考资料

- MCP 规范: https://modelcontextprotocol.io/specification/2025-06-18
- Claude Code MCP 文档: https://code.claude.com/docs/en/mcp
- Dart VM Service: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md
