import 'package:flutter/physics.dart';

/// Spring descriptions that define Neko's motion personality.
///
/// [nekoBounce] is the default bouncy entrance/press spring — it overshoots
/// slightly before settling, which is what makes interactions feel
/// satisfying. [nekoSnappy] is stiffer and is used where a quick, tight
/// settle is preferable to an overshoot.
abstract final class Springs {
  const Springs._();

  static const SpringDescription nekoBounce = SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 28.0,
  );

  static const SpringDescription nekoSnappy = SpringDescription(
    mass: 1.0,
    stiffness: 800.0,
    damping: 40.0,
  );
}
