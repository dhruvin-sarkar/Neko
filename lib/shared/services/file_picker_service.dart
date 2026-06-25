import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/logger.dart';

part 'file_picker_service.g.dart';

/// A picked document: its local [path] and original file [name].
typedef PickedFile = ({String path, String name});

/// Wraps `file_picker` for selecting cat documents (images or PDFs).
///
/// Returns the picked file, or `null` if the user cancelled or the pick failed
/// (failures are logged, never thrown into the UI).
class FilePickerService {
  const FilePickerService();

  static const List<String> _allowedExtensions = <String>[
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'heic',
    'webp',
  ];

  Future<PickedFile?> pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: false,
      );
      final PlatformFile? file = result?.files.singleOrNull;
      final String? path = file?.path;
      if (file == null || path == null) return null;
      return (path: path, name: file.name);
    } on Object catch (e, st) {
      AppLogger.warning('Document pick failed', e, st);
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
FilePickerService filePickerService(Ref ref) => const FilePickerService();
