# Chimera Flutter UI Automation

A Flutter library for UI automation with WebSocket and MCP (Model Context Protocol) server support, enabling AI-driven remote control, behavior recording/replay, and development tools integration.

## Features

- **WebSocket Server**: Built-in WebSocket server for remote control
- **MCP Server**: Model Context Protocol HTTP server for Claude Code integration
- **UI State Capture**: Real-time capture of UI elements from Semantics tree
- **Function Tracking**: Track and execute callback functions
- **Behavior Recording**: Record user interactions
- **Replay Engine**: Automatically replay recorded behaviors
- **Hot Reload/Restart**: Trigger Flutter Hot Reload (r) and Hot Restart (R) via MCP
- **Release Mode Compatible**: All features work in production builds

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  chimera_flutter_ui_automation:
    path: ../chimera_flutter_ui_automation
```

## Usage

### 1. Initialize the Library

```dart
import 'package:chimera_flutter_ui_automation/chimera_flutter_ui_automation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize automation with both WebSocket and MCP servers
  await AutomationController.initialize(
    port: 59322,           // WebSocket port
    mcpPort: 59323,        // MCP HTTP port (default: 59323)
    enableMCP: true,       // Enable MCP server
    enableRecording: true,
  );

  runApp(MyApp());
}
```

### 2. Connect with Claude Code

After starting your app, connect Claude Code to the MCP server:

```bash
# Add MCP server to Claude Code
claude mcp add --transport http chimera_flutter_ui http://127.0.0.1:59323/mcp

# The token will be printed in the console when the app starts
```

### 3. Use in Claude Code

Once connected, you can use these tools in Claude Code:

- `ui.snapshot` - Get current UI description
- `ui.tap` - Tap an element by ID
- `ui.tap_by_label` - Tap an element by label text
- `ui.input_text` - Input text into a field
- `ui.scroll` - Scroll the interface
- `ui.get_screen` - Get current screen name
- `ui.start_recording` - Start recording user actions
- `ui.stop_recording` - Stop recording
- `dev.hot_reload` - Trigger Hot Reload (r)
- `dev.hot_restart` - Trigger Hot Restart (R)
- `dev.vm_info` - Get Dart VM information

Example conversation with Claude Code:

```
You: 请查看当前界面
Claude: [calls ui.snapshot]
Current screen shows HomePage with buttons for...

You: 请点击性能测试按钮
Claude: [calls ui.tap_by_label with "性能测试"]
Successfully tapped the button

You: 执行 Hot Reload
Claude: [calls dev.hot_reload]
✅ Hot Reload successful
```

### 4. Use Tracked Widgets (Optional)

Replace standard widgets with tracked versions for better control:

```dart
// TrackedButton
TrackedButton(
  identifier: 'login_button',
  functionName: 'handleLogin',
  onPressed: () {
    // Your login logic
  },
  child: Text('Login'),
)

// TrackedTextField
TrackedTextField(
  identifier: 'username_field',
  functionName: 'onUsernameChanged',
  onChanged: (value) {
    // Handle text change
  },
  decoration: InputDecoration(labelText: 'Username'),
)

// TrackedGestureDetector
TrackedGestureDetector(
  identifier: 'custom_gesture',
  functionName: 'handleTap',
  onTap: () {
    // Handle tap
  },
  child: Container(/* ... */),
)
```

### 3. WebSocket API

Connect to `ws://localhost:59322` and send JSON commands:

#### Get UI State
```json
{
  "command": "getUI",
  "params": {
    "includeHidden": false,
    "includeFunctions": true
  }
}
```

Response:
```json
{
  "success": true,
  "data": {
    "timestamp": "2024-01-01T10:00:00Z",
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

#### Tap Element
```json
{
  "command": "tap",
  "params": {
    "identifier": "login_button"
  }
}
```

#### Input Text
```json
{
  "command": "input",
  "params": {
    "identifier": "username_field",
    "text": "admin"
  }
}
```

#### Start Recording
```json
{
  "command": "startRecord",
  "params": {
    "sessionId": "session_001"
  }
}
```

#### Stop Recording
```json
{
  "command": "stopRecord"
}
```

#### Replay Session
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

## Python Client Example

```python
import asyncio
import websockets
import json

async def get_ui_state():
    uri = "ws://localhost:59322"
    async with websockets.connect(uri) as websocket:
        request = {
            "command": "getUI",
            "params": {}
        }
        await websocket.send(json.dumps(request))
        response = await websocket.recv()
        data = json.loads(response)
        print(f"Current page: {data['data']['currentPage']}")
        for element in data['data']['elements']:
            print(f"  - {element['label']} ({element['identifier']})")

async def tap_button():
    uri = "ws://localhost:59322"
    async with websockets.connect(uri) as websocket:
        request = {
            "command": "tap",
            "params": {"identifier": "login_button"}
        }
        await websocket.send(json.dumps(request))
        response = await websocket.recv()
        print(json.loads(response))

asyncio.run(get_ui_state())
```

## Architecture

```
┌──────────────────────────────────────┐
│         AI Client (Python/JS)        │
└──────────────────────────────────────┘
                 ↓ WebSocket
┌──────────────────────────────────────┐
│    chimera_flutter_ui_automation     │
│  ┌────────────────────────────────┐  │
│  │     WebSocket Server           │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │     Command Handler            │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │  Function Registry             │  │
│  │  UI State Capture              │  │
│  │  Behavior Recorder             │  │
│  │  Replay Engine                 │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │  TrackedWidget Wrappers        │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────┐
│         Your Flutter App             │
└──────────────────────────────────────┘
```

## Security Notes

- The WebSocket server should only be enabled in development/testing environments
- Consider adding authentication for production use
- Do not expose the WebSocket port publicly

## License

MIT
