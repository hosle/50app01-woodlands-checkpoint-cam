import 'dart:convert';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/checkpoint_image.dart';
import '../models/constant.dart' as constants;
import '../models/traffic_camera.dart';

enum CheckpointType { woodlands, tuas, all }

class WoodlandsCheckpointsViewModel extends ChangeNotifier {
  WoodlandsCheckpointsViewModel({this.checkpointType = CheckpointType.all});

  final CheckpointType checkpointType;
  final List<CheckpointImage> _images = [];
  bool _isLoading = false;
  String? _errorMessage;

  UnmodifiableListView<CheckpointImage> get images =>
      UnmodifiableListView(_images);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<String, String> get _cameraIds {
    switch (checkpointType) {
      case CheckpointType.woodlands:
        return constants.woodlandsCameraIds;
      case CheckpointType.tuas:
        return constants.tuasCameraIds;
      case CheckpointType.all:
        return constants.seletedCameraIds;
    }
  }

  Future<void> loadImages() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      const url =
          'https://datamall2.mytransport.sg/ltaodataservice/Traffic-Imagesv2';
      const accountKey = 'SlnP4GBZQMeeVoVtTZIXkw==';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Accept': 'application/json', 'AccountKey': accountKey},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final valueList = jsonData['value'] as List<dynamic>?;

        if (valueList != null && valueList.isNotEmpty) {
          // Create a map of cameraID to TrafficCamera for quick lookup
          final cameraMap = <String, TrafficCamera>{};
          for (final item in valueList) {
            final camera = TrafficCamera.fromJson(item as Map<String, dynamic>);
            cameraMap[camera.cameraID] = camera;
          }

          // Build images list in the order defined in camera IDs
          _images.clear();
          for (final entry in _cameraIds.entries) {
            final cameraId = entry.key;
            final title = entry.value;
            final camera = cameraMap[cameraId];

            if (camera != null) {
              _images.add(
                CheckpointImage(
                  title: title,
                  imageUrl: camera.imageLink,
                  capturedAt: _extractCaptureTime(camera.imageLink),
                ),
              );
            }
          }
        } else {
          _errorMessage = 'No traffic camera data available';
        }
      } else {
        _errorMessage =
            'Failed to load traffic images. Status: ${response.statusCode}';
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      _errorMessage = 'Unable to load checkpoint images: ${error.toString()}';
      debugPrint('WoodlandsCheckpointsViewModel loadImages error: $error');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  DateTime? _extractCaptureTime(String imageUrl) {
    final folderMatch =
        RegExp(r'/(\d{4}-\d{2}-\d{2})/(\d{2})-(\d{2})/').firstMatch(imageUrl);
    if (folderMatch != null) {
      final datePart = folderMatch.group(1)!; // e.g. 2025-11-13
      final hourPart = folderMatch.group(2)!; // e.g. 15
      final minutePart = folderMatch.group(3)!; // e.g. 20

      try {
        final parsedDate = DateTime.parse('$datePart ${hourPart}:${minutePart}:00');
        return parsedDate;
      } catch (_) {
        // Continue to fallback parsing below.
      }
    }

    // Fallback to legacy pattern (e.g. .../20251113_072059_) if present.
    final legacyMatch = RegExp(r'/(\d{8})_(\d{6})_').firstMatch(imageUrl);
    if (legacyMatch == null) {
      return null;
    }

    final datePart = legacyMatch.group(1)!;
    final timePart = legacyMatch.group(2)!;

    try {
      final year = int.parse(datePart.substring(0, 4));
      final month = int.parse(datePart.substring(4, 6));
      final day = int.parse(datePart.substring(6, 8));
      final hour = int.parse(timePart.substring(0, 2));
      final minute = int.parse(timePart.substring(2, 4));
      final second = int.parse(timePart.substring(4, 6));

      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }
}
