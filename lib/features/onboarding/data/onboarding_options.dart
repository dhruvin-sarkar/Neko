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

  static const List<CoatOption> coats = <CoatOption>[
    CoatOption(
      value: 'ginger',
      label: 'Ginger',
      circleColor: Color(0xFFFF8C42),
    ),
    CoatOption(value: 'black', label: 'Black', circleColor: Color(0xFF2D2D2D)),
    CoatOption(
      value: 'white',
      label: 'White',
      circleColor: Color(0xFFF0F0F0),
      needsBorder: true,
    ),
    CoatOption(value: 'tabby', label: 'Tabby', circleColor: Color(0xFF8B7355)),
    CoatOption(
      value: 'calico',
      label: 'Calico',
      circleColor: Color(0xFFC8A882),
    ),
    CoatOption(value: 'grey', label: 'Grey', circleColor: Color(0xFF9E9E9E)),
    CoatOption(
      value: 'tortoiseshell',
      label: 'Tortoiseshell',
      circleColor: Color(0xFFB8651B),
    ),
    CoatOption(value: 'other', label: 'Other', circleColor: Color(0xFFBDBDBD)),
  ];

  static const List<ActivityOption> activities = <ActivityOption>[
    ActivityOption(
      value: 'couch',
      label: 'Couch potato',
      description: 'Indoor, mostly naps',
      icon: Icons.weekend_rounded,
    ),
    ActivityOption(
      value: 'active',
      label: 'Playful indoor',
      description: 'Active but stays inside',
      icon: Icons.toys_rounded,
    ),
    ActivityOption(
      value: 'outdoor',
      label: 'Outdoor explorer',
      description: 'Goes outside regularly',
      icon: Icons.park_rounded,
    ),
  ];
}
