import 'dart:convert';

import 'package:flutter/widgets.dart';

// Map literals keep insertion order, so the first key is the least recently used.
final _cache = <String, MemoryImage>{};
const _maxCachedImages = 100;

/// Returns an [ImageProvider] for a base64-encoded image stored in Firestore.
///
/// Providers are cached by their data so every Firestore snapshot doesn't
/// decode the image again or make it flicker as a "new" image.
ImageProvider base64Image(String data) {
  final cached = _cache.remove(data);
  if (cached != null) {
    _cache[data] = cached;
    return cached;
  }

  final provider = MemoryImage(base64Decode(data));
  _cache[data] = provider;
  if (_cache.length > _maxCachedImages) _cache.remove(_cache.keys.first);
  return provider;
}
