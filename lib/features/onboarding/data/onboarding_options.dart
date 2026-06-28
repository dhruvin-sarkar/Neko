import 'package:flutter/material.dart';

import '../models/activity_option.dart';
import '../models/coat_option.dart';

/// Static option data for the onboarding choice steps.
abstract final class OnboardingOptions {
  const OnboardingOptions._();

  static const List<String> breeds = <String>[
    'Domestic Shorthair',
    'Domestic Longhair',
    'Persian',
    'Maine Coon',
    'Siamese',
    'Bengal',
    'Ragdoll',
    'British Shorthair',
    'Scottish Fold',
    'Russian Blue',
    'Sphynx',
    'Abyssinian',
    'Norwegian Forest Cat',
    'Other',
  ];

  // The twelve coats, each mapped to one of the 12 cat-coat themes. Selecting a
  // coat re-themes the whole app to match. `value` is unique per coat (it equals
  // the themeId) and is stored as the cat's `colorType`; the no-photo avatar
  // colour is derived from it via [AppColors.catColorFor].
  static const List<CoatOption> coats = <CoatOption>[
    CoatOption(
      value: 'gingerTabby',
      label: 'Orange Tabby',
      circleColor: Color(0xFFFF6B35),
      themeId: 'gingerTabby',
    ),
    CoatOption(
      value: 'midnightBlack',
      label: 'Solid Black',
      circleColor: Color(0xFF1A1A2E),
      themeId: 'midnightBlack',
    ),
    CoatOption(
      value: 'snowWhite',
      label: 'Snow White',
      circleColor: Color(0xFFE8EBFF),
      themeId: 'snowWhite',
      needsBorder: true,
    ),
    CoatOption(
      value: 'russianBlue',
      label: 'Grey / Blue',
      circleColor: Color(0xFF5C7E94),
      themeId: 'russianBlue',
    ),
    CoatOption(
      value: 'creamBeige',
      label: 'Cream',
      circleColor: Color(0xFFE8A838),
      themeId: 'creamBeige',
    ),
    CoatOption(
      value: 'calico',
      label: 'Calico',
      circleColor: Color(0xFFF15A29),
      themeId: 'calico',
    ),
    CoatOption(
      value: 'tortoiseshell',
      label: 'Tortoiseshell',
      circleColor: Color(0xFFC0632A),
      themeId: 'tortoiseshell',
    ),
    CoatOption(
      value: 'sealPoint',
      label: 'Seal Point',
      circleColor: Color(0xFF6D4C41),
      themeId: 'sealPoint',
    ),
    CoatOption(
      value: 'chocolateBrown',
      label: 'Chocolate',
      circleColor: Color(0xFF5D4037),
      themeId: 'chocolateBrown',
    ),
    CoatOption(
      value: 'silverTabby',
      label: 'Silver',
      circleColor: Color(0xFF5C7A8C),
      themeId: 'silverTabby',
    ),
    CoatOption(
      value: 'lilacLavender',
      label: 'Lilac',
      circleColor: Color(0xFF9575CD),
      themeId: 'lilacLavender',
    ),
    CoatOption(
      value: 'tuxedo',
      label: 'Tuxedo',
      circleColor: Color(0xFF212121),
      themeId: 'tuxedo',
    ),
  ];

  static const List<ActivityOption> activities = <ActivityOption>[
    ActivityOption(
      value: 'couch',
      label: 'Low Activity',
      description: 'Sleeps most of the day with short indoor play sessions',
      icon: Icons.weekend_rounded,
    ),
    ActivityOption(
      value: 'active',
      label: 'Moderately Active',
      description: 'Regular indoor play and occasional exploration',
      icon: Icons.toys_rounded,
    ),
    ActivityOption(
      value: 'outdoor',
      label: 'Highly Active',
      description: 'Frequent running, climbing, and outdoor exploration',
      icon: Icons.park_rounded,
    ),
  ];
}
