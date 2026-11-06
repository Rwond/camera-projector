import 'package:flutter/services.dart';

class ProjectionStatus {
  const ProjectionStatus({
    required this.running,
    this.ip,
    this.port,
    this.url,
    this.error,
  });

  factory ProjectionStatus.fromMap(Map<dynamic, dynamic> map) {
    final rawPort = map['port'];
    return ProjectionStatus(
      running: map['running'] == true,
      ip: map['ip'] as String?,
      port: rawPort is int
          ? rawPort
          : (rawPort is num ? rawPort.toInt() : null),
      url: map['url'] as String?,
      error: map['error'] as String?,
    );
  }

  final bool running;
  final String? ip;
  final int? port;
  final String? url;
  final String? error;
}

/// Pont vers le prototype natif Android (MediaProjection + serveur MJPEG).
class ProjectionService {
  const ProjectionService();

  static const MethodChannel _channel = MethodChannel(
    'com.swvertex.camera_projector/projection_test',
  );

  Future<ProjectionStatus> status() async {
    final map = await _channel.invokeMapMethod<String, dynamic>('status');
    return ProjectionStatus.fromMap(map ?? const {});
  }

  Future<ProjectionStatus> start() async {
    final map = await _channel.invokeMapMethod<String, dynamic>('start');
    return ProjectionStatus.fromMap(map ?? const {});
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }
}
