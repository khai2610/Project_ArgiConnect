class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? location;
  final String? phone;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.location,
    this.phone,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      location: json['location'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "email": email,
      "role": role,
      "location": location,
      "phone": phone,
    };
  }
}
