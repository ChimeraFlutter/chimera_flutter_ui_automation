import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart' as ws;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'command_handler.dart';

/// WebSocket server for remote control
class WebSocketServer {
  HttpServer? _server;
  final int port;
  final BuildContext? context;
  final List<WebSocketChannel> _clients = [];

  WebSocketServer({
    required this.port,
    this.context,
  });

  /// Start the WebSocket server
  Future<void> start() async {
    if (_server != null) {
      throw StateError('Server is already running');
    }

    final handler = ws.webSocketHandler((WebSocketChannel webSocket) {
      _clients.add(webSocket);
      print('Client connected. Total clients: ${_clients.length}');

      final commandHandler = CommandHandler(context: context);

      webSocket.stream.listen(
        (message) async {
          print('Received message: $message');
          final response = await commandHandler.handleMessage(message as String);
          webSocket.sink.add(response);
        },
        onDone: () {
          _clients.remove(webSocket);
          print('Client disconnected. Total clients: ${_clients.length}');
        },
        onError: (error) {
          print('WebSocket error: $error');
          _clients.remove(webSocket);
        },
      );
    });

    final cascade = shelf.Cascade()
        .add(_createHealthCheckHandler())
        .add(handler);

    _server = await shelf_io.serve(
      cascade.handler,
      InternetAddress.anyIPv4,
      port,
    );

    print('WebSocket server started on port $port');
  }

  /// Stop the WebSocket server
  Future<void> stop() async {
    if (_server == null) {
      return;
    }

    // Close all client connections
    for (final client in _clients) {
      await client.sink.close();
    }
    _clients.clear();

    await _server!.close(force: true);
    _server = null;
    print('WebSocket server stopped');
  }

  /// Check if server is running
  bool get isRunning => _server != null;

  /// Get number of connected clients
  int get clientCount => _clients.length;

  shelf.Handler _createHealthCheckHandler() {
    return (shelf.Request request) {
      if (request.url.path == 'health') {
        return shelf.Response.ok('OK');
      }
      return shelf.Response.notFound('Not Found');
    };
  }
}
