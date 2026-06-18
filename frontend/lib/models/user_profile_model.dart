class UserProfileModel {
  const UserProfileModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.cropType,
    required this.location,
    required this.language,
    required this.soilType,
    required this.cropStage,
  });

  final String uid;
  final String name;
  final String phone;
  final String cropType;
  final String location;
  final String language;
  final String soilType;
  final String cropStage;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'cropType': cropType,
      'location': location,
      'language': language,
      'soilType': soilType,
      'cropStage': cropStage,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      cropType: map['cropType']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      language: map['language']?.toString() ?? 'English',
      soilType: map['soilType']?.toString() ?? 'Loam',
      cropStage: map['cropStage']?.toString() ?? 'Vegetative',
    );
  }
}
