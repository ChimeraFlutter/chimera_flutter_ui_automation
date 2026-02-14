# Python 客户端使用指南

## 前提条件

确保已安装 websockets 库：
```bash
pip3 install websockets
```

## 快速开始

### 1. 启动 Flutter 应用

```bash
cd /Users/acewill/flutter_hello
flutter run -d macos
```

应用启动后，WebSocket 服务器会自动在端口 59322 启动。

### 2. 查看当前页面

```bash
cd /Users/acewill/chimera_flutter_ui_automation
python3 check_page.py
```

这会显示：
- 当前页面名称
- 所有可见元素列表
- 每个元素的 ID、类型、可用动作和函数名

### 3. 点击按钮

```bash
python3 click_button.py home_performance_test_button
```

可用的按钮 ID：
- `home_performance_test_button` - 进入性能测试页面
- `home_wrap_examples_button` - Wrap 组件示例
- `home_webview_button` - WebView 页面
- `home_list_page_button` - List.builder 示例
- `home_lifecycle_button` - Widget 生命周期验证
- `home_rich_text_button` - 图文混排深度研究
- `home_sliver_button` - Sliver 滚动布局详解

### 4. 完整测试

```bash
python3 test_client.py
```

这会运行完整的测试套件，包括：
- 连接测试
- 获取 UI 状态
- 自动点击第一个按钮

## 自定义脚本示例

### 简单连接示例

```python
import asyncio
import websockets
import json

async def main():
    uri = "ws://localhost:59322"
    async with websockets.connect(uri) as ws:
        # 获取 UI
        await ws.send(json.dumps({"command": "getUI"}))
        response = await ws.recv()
        print(json.loads(response))

asyncio.run(main())
```

### 点击按钮示例

```python
import asyncio
import websockets
import json

async def tap_button(button_id):
    uri = "ws://localhost:59322"
    async with websockets.connect(uri) as ws:
        request = {
            "command": "tap",
            "params": {"identifier": button_id}
        }
        await ws.send(json.dumps(request))
        response = await ws.recv()
        print(json.loads(response))

asyncio.run(tap_button("home_performance_test_button"))
```

### 输入文本示例

```python
import asyncio
import websockets
import json

async def input_text(field_id, text):
    uri = "ws://localhost:59322"
    async with websockets.connect(uri) as ws:
        request = {
            "command": "input",
            "params": {
                "identifier": field_id,
                "text": text
            }
        }
        await ws.send(json.dumps(request))
        response = await ws.recv()
        print(json.loads(response))

asyncio.run(input_text("username_field", "admin"))
```

## WebSocket 命令参考

### getUI - 获取 UI 状态

```json
{
  "command": "getUI",
  "params": {}
}
```

### tap - 点击元素

```json
{
  "command": "tap",
  "params": {
    "identifier": "button_id"
  }
}
```

### input - 输入文本

```json
{
  "command": "input",
  "params": {
    "identifier": "field_id",
    "text": "your text"
  }
}
```

### startRecord - 开始录制

```json
{
  "command": "startRecord",
  "params": {
    "sessionId": "session_001"
  }
}
```

### stopRecord - 停止录制

```json
{
  "command": "stopRecord"
}
```

### replay - 回放录制

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

## 故障排除

### 连接失败

如果看到 "无法连接到 ws://localhost:59322"：
1. 确保 flutter_hello 应用正在运行
2. 检查控制台是否显示 "Chimera UI Automation 已启动，WebSocket 端口: 59322"
3. 确保没有其他程序占用 59322 端口

### 找不到元素

如果点击按钮失败：
1. 先运行 `python3 check_page.py` 查看当前页面的所有元素
2. 确认元素 ID 是否正确
3. 确认元素是否可见（visible: true）

### Python 依赖问题

如果提示找不到 websockets 模块：
```bash
pip3 install websockets
```

或使用虚拟环境：
```bash
python3 -m venv venv
source venv/bin/activate
pip install websockets
```
