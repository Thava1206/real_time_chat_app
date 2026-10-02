import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_service.dart';
import '../theme/app_theme.dart';
import 'liquid_glass.dart';

enum PhotoAction { gallery, camera, remove }

/// Asks where a photo should come from, returning null if dismissed.
///
/// When there's no camera and nothing to remove, the gallery is the only
/// option, so it's returned straight away without showing the sheet.
Future<PhotoAction?> showPhotoSourceSheet(
  BuildContext context, {
  bool canRemove = false,
}) async {
  if (!ImageService.supportsCamera && !canRemove) return PhotoAction.gallery;

  return showModalBottomSheet<PhotoAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => LiquidGlassSurface(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      color: context.surfaces.isGlass
          ? const Color(0xFF333C57)
          : context.surfaces.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(PhotoAction.gallery),
              ),
              if (ImageService.supportsCamera)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take photo'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(PhotoAction.camera),
                ),
              if (canRemove)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.terracotta,
                    shadows: [],
                  ),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(color: AppColors.terracotta),
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(PhotoAction.remove),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

extension PhotoActionSource on PhotoAction {
  /// The picker source for this action; null for [PhotoAction.remove].
  ImageSource? get source => switch (this) {
    PhotoAction.gallery => ImageSource.gallery,
    PhotoAction.camera => ImageSource.camera,
    PhotoAction.remove => null,
  };
}
