import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/logger.dart';

part 'image_picker_service.g.dart';

/// Thin wrapper over `image_picker` for choosing a cat photo.
///
/// Returns the local file path, or `null` if the user cancelled or the pick
/// failed (failures are logged, never thrown into the UI).
class ImagePickerService {
  const ImagePickerService(this._picker);

  final ImagePicker _picker;

  Future<String?> pick(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return file?.path;
    } on Object catch (e, st) {
      AppLogger.warning('Image pick failed', e, st);
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
ImagePickerService imagePickerService(Ref ref) =>
    ImagePickerService(ImagePicker());
