import 'package:flutter/material.dart';
import 'package:chimera_flutter_ui_automation/chimera_flutter_ui_automation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the automation library
  await AutomationController.initialize(
    port: 59322,
    enableRecording: true,
    enableScreenshot: true,        // Enable screenshot capture
    screenshotRateLimitMs: 1000,   // 1 screenshot per second
  );

  runApp(
    ScreenshotCapableApp(          // Wrap app with screenshot capability
      screenshotKey: AutomationController.screenshotKey,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chimera UI Automation Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;
  final TextEditingController _textController = TextEditingController();

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _handleTextChange(String text) {
    print('Text changed: $text');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chimera UI Automation Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            TrackedButton(
              identifier: 'increment_button',
              functionName: 'incrementCounter',
              onPressed: _incrementCounter,
              child: const Text('Increment'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: TrackedTextField(
                identifier: 'text_input',
                functionName: 'handleTextChange',
                controller: _textController,
                onChanged: _handleTextChange,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter text',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
