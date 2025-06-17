class DroneService {
  final String id;
  final String providerId;
  final String serviceName;
  final String description;
  final double pricePerHa;
  final List<String> availableAreas;
  final List<String> images;

  DroneService({
    required this.id,
    required this.providerId,
    required this.serviceName,
    required this.description,
    required this.pricePerHa,
    required this.availableAreas,
    required this.images,
  });

  factory DroneService.fromJson(Map<String, dynamic> json) {
    return DroneService(
      id: json['_id'],
      providerId: json['providerId'],
      serviceName: json['serviceName'],
      description: json['description'],
      pricePerHa: json['pricePerHa'].toDouble(),
      availableAreas: List<String>.from(json['availableAreas']),
      images: List<String>.from(json['images']),
    );
  }
}
