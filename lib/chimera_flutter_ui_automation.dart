library chimera_flutter_ui_automation;

// Main controller
export 'automation_controller.dart';

// Widgets
export 'src/widgets/tracked_button.dart';
export 'src/widgets/tracked_text_field.dart';
export 'src/widgets/tracked_gesture_detector.dart';
export 'src/widgets/screenshot_capable_app.dart';

// Models
export 'src/models/function_info.dart';
export 'src/models/ui_element.dart';
export 'src/models/ui_snapshot.dart';
export 'src/models/user_action.dart';
export 'src/models/recording_session.dart';
export 'src/models/screenshot_result.dart';

// Core functionality
export 'src/core/function_registry.dart';
export 'src/core/ui_state_capture.dart';
export 'src/core/behavior_recorder.dart';
export 'src/core/replay_engine.dart';
export 'src/core/navigator_observer.dart';
export 'src/core/screenshot_service.dart';

// Exceptions
export 'src/exceptions/screenshot_exception.dart';

// Servers
export 'src/server/mcp_server.dart';
