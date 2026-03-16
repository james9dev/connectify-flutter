import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfilePhotoPickerHelper {
  const ProfilePhotoPickerHelper._();

  static Future<CroppedFile?> cropImageToFourByFive(String sourcePath) {
    return ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      maxWidth: 1080,
      maxHeight: 1350,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '사진 자르기',
          toolbarColor: const Color(0xFFFFC629),
          toolbarWidgetColor: const Color(0xFF14130F),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: '사진 자르기', aspectRatioLockEnabled: true, resetAspectRatioEnabled: false),
      ],
    );
  }

  static Future<void> validateImageBytes(List<int> bytes) async {
    final image = await decodeImageFromList(Uint8List.fromList(bytes));

    if (image.width < 320 || image.height < 320) {
      throw Exception('사진의 최소 해상도는 320px 이상이어야 합니다.');
    }

    final ratio = image.width / image.height;
    const targetRatio = 4 / 5;
    if ((ratio - targetRatio).abs() > 0.08) {
      throw Exception('사진 비율은 4:5에 맞춰주세요.');
    }
  }

  static String? resolveSupportedContentType(String fileName) {
    final split = fileName.split('.');
    if (split.length < 2) {
      return null;
    }

    final ext = split.last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }
}
