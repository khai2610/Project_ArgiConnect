class Booking {
  final String id;
  final String farmerId;
  final String serviceId;
  final String providerId;
  final String status;
  final DateTime scheduledDate;
  final double areaSize;
  final String location;
  final String? notes;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.farmerId,
    required this.serviceId,
    required this.providerId,
    required this.status,
    required this.scheduledDate,
    required this.areaSize,
    required this.location,
    this.notes,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'],
      farmerId: json['farmerId'],
      serviceId: json['serviceId'],
      providerId: json['providerId'],
      status: json['status'],
      scheduledDate: DateTime.parse(json['scheduledDate']),
      areaSize: (json['areaSize'] as num).toDouble(),
      location: json['location'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'farmerId': farmerId,
      'serviceId': serviceId,
      'providerId': providerId,
      'status': status,
      'scheduledDate': scheduledDate.toIso8601String(),
      'areaSize': areaSize,
      'location': location,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
