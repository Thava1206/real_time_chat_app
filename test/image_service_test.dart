import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:real_time_chat_app/services/image_service.dart';

void main() {
  Uint8List noisyPng(int width, int height) {
    final image = img.Image(width: width, height: height);
    for (final pixel in image) {
      final seed = pixel.x * 31 + pixel.y * 17;
      pixel.setRgb(seed % 256, (seed * 7) % 256, (seed * 13) % 256);
    }
    return img.encodePng(image);
  }

  test('keeps images that are already within budget', () {
    final bytes = noisyPng(8, 8);

    final result = shrinkImage((
      bytes: bytes,
      maxDimension: 256,
      maxBytes: bytes.length,
    ));

    expect(result, same(bytes));
  });

  test('resizes and re-encodes large images under the byte limit', () {
    final bytes = noisyPng(1200, 800);

    final result = shrinkImage((
      bytes: bytes,
      maxDimension: 256,
      maxBytes: 20 * 1024,
    ));

    expect(result.length, lessThanOrEqualTo(20 * 1024));
    final decoded = img.decodeJpg(result)!;
    expect(decoded.width, lessThanOrEqualTo(256));
    expect(decoded.height, lessThanOrEqualTo(256));
  });

  test('rejects bytes that are not an image', () {
    expect(
      () => shrinkImage((
        bytes: Uint8List(100),
        maxDimension: 256,
        maxBytes: 1000,
      )),
      throwsFormatException,
    );
  });

  test('resizes an image whose bytes fit but dimensions are too large', () {
    final bytes = img.encodePng(img.Image(width: 1000, height: 800));

    final result = shrinkImage((
      bytes: bytes,
      maxDimension: 256,
      maxBytes: bytes.length,
    ));

    final decoded = img.decodeImage(result)!;
    expect(decoded.width, lessThanOrEqualTo(256));
    expect(decoded.height, lessThanOrEqualTo(256));
  });
}
