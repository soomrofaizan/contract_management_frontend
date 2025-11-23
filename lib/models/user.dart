// models/user.dart
class User {
  final int? id;
  final String mobileNumber;
  final String fullName;
  final bool isActive;
  final DateTime? createdDate;

  User({
    this.id,
    required this.mobileNumber,
    required this.fullName,
    this.isActive = true,
    this.createdDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      mobileNumber: json['mobileNumber'],
      fullName: json['fullName'],
      isActive: json['isActive'] ?? true,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'mobileNumber': mobileNumber,
      'fullName': fullName,
      'isActive': isActive,
      if (createdDate != null) 'createdDate': createdDate!.toIso8601String(),
    };
  }
}

// models/auth_response.dart
