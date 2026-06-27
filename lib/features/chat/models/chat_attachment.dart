import 'package:flutter/foundation.dart';

/// An attachment the user adds to a chat message.
///
/// [path] is a local file path (picked on-device). When the LLM API is wired
/// in, attachments will be uploaded and [path] can hold the remote URL instead.
@immutable
class ChatAttachment {
  const ChatAttachment({
    required this.path,
    required this.name,
    this.isImage = true,
  });

  final String path;
  final String name;
  final bool isImage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAttachment &&
          other.path == path &&
          other.name == name &&
          other.isImage == isImage;

  @override
  int get hashCode => Object.hash(path, name, isImage);
}
