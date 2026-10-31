
class Institution {
  final int id;
  final String name;
  final String city;
  final String type;
  final String description;
  final String address;
  final String phone;
  final String email;
  final String websiteUrl;
  final String logoUrl;

  // Institution cover
  final String coverTitle;
  final String coverDescription;
  final String coverImageUrl;

  final double? latitude;
  final double? longitude;

  const Institution({
    required this.id,
    required this.name,
    required this.city,
    this.type = '',
    this.description = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.websiteUrl = '',
    this.logoUrl = '',
    this.coverTitle = '',
    this.coverDescription = '',
    this.coverImageUrl = '',
    this.latitude,
    this.longitude,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];

    if (idValue is! num) {
      throw const FormatException('Institution id is missing');
    }

    return Institution(
      id: idValue.toInt(),
      name: json['name']?.toString() ?? '',
      city: (json['city'] ?? json['village'])?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      websiteUrl: json['websiteUrl']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString() ?? '',
      coverTitle: json['coverTitle']?.toString() ?? '',
      coverDescription:
      json['coverDescription']?.toString() ?? '',
      coverImageUrl:
      json['coverImageUrl']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
