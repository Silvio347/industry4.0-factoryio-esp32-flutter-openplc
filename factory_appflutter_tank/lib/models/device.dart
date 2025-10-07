class Device {
  final String id;
  final String name;
  final String type;
  final String userId;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.userId,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'].toString(),
      name: json['name'],
      type: json['type'] ?? '',
      userId: json['user_id'].toString(),
    );
  }
}
