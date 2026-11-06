import '../../core/api_client.dart';

class Device {
  Device({
    required this.id,
    required this.type,
    required this.platform,
    this.model,
    required this.status,
    this.lastActiveAt,
  });

  final String id;
  final String type;
  final String platform;
  final String? model;
  final String status;
  final String? lastActiveAt;

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'],
    type: json['type'],
    platform: json['platform'],
    model: json['model'],
    status: json['status'],
    lastActiveAt: json['lastActiveAt'],
  );
}

class DevicesService {
  DevicesService(this._api);

  final ApiClient _api;

  Future<List<Device>> list() async {
    final result = await _api.get('/devices') as List<dynamic>;
    return result.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Device> register({required String type, required String platform, String? model}) async {
    final result = await _api.post('/devices', {
      'type': type,
      'platform': platform,
      if (model != null && model.isNotEmpty) 'model': model,
    });
    return Device.fromJson(result as Map<String, dynamic>);
  }

  Future<void> revoke(String id) => _api.delete('/devices/$id');
}
