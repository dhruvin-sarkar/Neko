/// The built-in cat avatars I offer when someone doesn't add their own photo.
/// I save the chosen id on the cat as `avatarPreset`; the images live in
/// `assets/images/avatars/`.
abstract final class AvatarPresets {
  const AvatarPresets._();

  /// Stable ids, also the asset file stems.
  static const List<String> ids = <String>[
    'avatar_1',
    'avatar_2',
    'avatar_3',
    'avatar_4',
    'avatar_5',
    'avatar_6',
  ];

  /// Resolves a preset id to its bundled asset path.
  static String assetFor(String id) => 'assets/images/avatars/$id.png';

  /// Whether [id] is a known preset.
  static bool isPreset(String? id) => id != null && ids.contains(id);
}
