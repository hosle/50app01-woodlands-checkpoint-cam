class CheckpointImage {
  const CheckpointImage({
    required this.title,
    required this.imageUrl,
    this.capturedAt,
  });

  final String title;
  final String imageUrl;
  final DateTime? capturedAt;
}

