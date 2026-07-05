/// Shipping address returned by `GET /api/v1/addresses`.
class AddressDTO {
  final String id;
  final String receiverName;
  final String phone;
  final String streetAddress;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  AddressDTO({
    required this.id,
    required this.receiverName,
    required this.phone,
    required this.streetAddress,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory AddressDTO.fromJson(Map<String, dynamic> json) {
    return AddressDTO(
      id: json['id'] as String,
      receiverName: json['receiverName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      streetAddress: json['streetAddress'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

/// Body for `POST /api/v1/addresses`.
///
/// `latitude` / `longitude` are required by the API. Since the app has no
/// map picker yet, callers may pass sensible defaults.
class AddressRequest {
  final String receiverName;
  final String phone;
  final String streetAddress;
  final double latitude;
  final double longitude;
  final bool isDefault;

  AddressRequest({
    required this.receiverName,
    required this.phone,
    required this.streetAddress,
    this.latitude = 10.762622, // Ho Chi Minh City centre as fallback
    this.longitude = 106.660172,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'receiverName': receiverName,
        'phone': phone,
        'streetAddress': streetAddress,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };
}
