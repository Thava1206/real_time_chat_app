import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Picks photos and shrinks them so they fit inside a Firestore document.
///
/// Images are stored as base64 strings rather than in Firebase Storage, so the
/// app keeps working on the free Firebase plan. Firestore documents are capped
/// at 1 MiB, which is why everything is resized and re-encoded first.
class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Profile photos are read for every contact and chat row, so keep them tiny.
  static const profilePhotoSize = 256;
  static const maxProfilePhotoBytes = 60 * 1024;

  static const messageImageSize = 1280;
  static const maxMessageImageBytes = 600 * 1024;

  final ImagePicker _picker;

  /// Whether [ImageSource.camera] can be offered on this platform.
  static bool get supportsCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Returns the chosen photo as base64, or null if the user cancelled.
  Future<String?> pickProfilePhoto(ImageSource source) =>
      _pick(source, profilePhotoSize, maxProfilePhotoBytes);

  /// Returns the chosen image as base64, or null if the user cancelled.
  Future<String?> pickMessageImage(ImageSource source) =>
      _pick(source, messageImageSize, maxMessageImageBytes);

  Future<String?> _pick(
    ImageSource source,
    int maxDimension,
    int maxBytes,
  ) async {
    // The size hints are applied natively on mobile and web, which makes the
    // Dart-side shrinking below cheap; desktop pickers ignore them.
    final file = await _picker.pickImage(
      source: source,
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final shrunk = await compute(shrinkImage, (
      bytes: bytes,
      maxDimension: maxDimension,
      maxBytes: maxBytes,
    ));
    return base64Encode(shrunk);
  }
}

/// Re-encodes [bytes] as a JPEG no larger than `maxDimension` on its longest
/// side and `maxBytes` in size. Images already within budget are kept as-is.
///
/// Throws a [FormatException] if the bytes aren't a supported image.
Uint8List shrinkImage(
  ({Uint8List bytes, int maxDimension, int maxBytes}) args,
) {
  final (:bytes, :maxDimension, :maxBytes) = args;
  if (bytes.length <= maxBytes) return bytes;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Unsupported image format');
  }

  var image = img.bakeOrientation(decoded);
  if (max(image.width, image.height) > maxDimension) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxDimension)
        : img.copyResize(image, height: maxDimension);
  }

  while (true) {
    for (final quality in const [85, 70, 55, 40]) {
      final jpg = img.encodeJpg(image, quality: quality);
      if (jpg.length <= maxBytes) return jpg;
    }
    image = img.copyResize(image, width: max(1, image.width * 3 ~/ 4));
  }
}
