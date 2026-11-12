import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/property.dart';

/// Icons live in the presentation layer so the domain stays UI-free.
extension PropertyTypeIcon on PropertyType {
  IconData get icon => switch (this) {
    PropertyType.apartment => LucideIcons.building2,
    PropertyType.house => LucideIcons.house,
    PropertyType.studio => LucideIcons.sofa,
    PropertyType.room => LucideIcons.doorOpen,
  };
}

extension FacilityIcon on Facility {
  IconData get icon => switch (this) {
    Facility.water => LucideIcons.droplet,
    Facility.wifi => LucideIcons.wifi,
    Facility.security => LucideIcons.shieldCheck,
    Facility.parking => LucideIcons.car,
    Facility.backupPower => LucideIcons.zap,
  };
}
