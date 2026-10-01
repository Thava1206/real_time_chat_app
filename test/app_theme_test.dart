import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/theme/app_theme.dart';

void main() {
  test('appearance themes expose the expected semantic surfaces', () {
    expect(lightAppTheme.brightness, Brightness.light);
    expect(darkAppTheme.brightness, Brightness.dark);
    expect(liquidGlassTheme.brightness, Brightness.dark);
    expect(liquidGlassTheme.extension<AppSurfaceColors>()!.isGlass, isTrue);
    expect(lightAppTheme.extension<AppSurfaceColors>()!.isGlass, isFalse);
    expect(darkAppTheme.extension<AppSurfaceColors>()!.isGlass, isFalse);
  });
}
