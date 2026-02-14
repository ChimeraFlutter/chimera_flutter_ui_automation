/// WebSocket command request
class WSRequest {
  final String command;
  final Map<String, dynamic>? params;

  WSRequest({
    required this.command,
    this.params,
  });

  factory WSRequest.fromJson(Map<String, dynamic> json) {
    return WSRequest(
      command: json['command'] as String,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'command': command,
      if (params != null) 'params': params,
    };
  }
}

/// WebSocket command response
class WSResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final String? error;

  WSResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory WSResponse.success({dynamic data, String? message}) {
    return WSResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory WSResponse.error(String error) {
    return WSResponse(
      success: false,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (data != null) 'data': data,
      if (message != null) 'message': message,
      if (error != null) 'error': error,
    };
  }
}
