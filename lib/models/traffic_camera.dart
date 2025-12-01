class TrafficCamera {
  const TrafficCamera({
    required this.cameraID,
    required this.latitude,
    required this.longitude,
    required this.imageLink,
  });

  final String cameraID;
  final double latitude;
  final double longitude;
  final String imageLink;

  factory TrafficCamera.fromJson(Map<String, dynamic> json) {
    return TrafficCamera(
      cameraID: json['CameraID'] as String,
      latitude: (json['Latitude'] as num).toDouble(),
      longitude: (json['Longitude'] as num).toDouble(),
      imageLink: json['ImageLink'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CameraID': cameraID,
      'Latitude': latitude,
      'Longitude': longitude,
      'ImageLink': imageLink,
    };
  }

  @override
  String toString() {
    return 'TrafficCamera(cameraID: $cameraID, latitude: $latitude, '
        'longitude: $longitude, imageLink: $imageLink)';
  }
}
