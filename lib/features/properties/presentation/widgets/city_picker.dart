import 'package:flutter/material.dart';

import '../../../../core/domain/rwanda_cities.dart';
import '../../../../core/widgets/pickers.dart';

/// Opens a bottom sheet of Rwandan towns.
Future<RwandaCity?> pickCity(
  BuildContext context, {
  required String title,
  required RwandaCity selected,
}) => showOptionsSheet<RwandaCity>(
  context: context,
  title: title,
  options: RwandaCity.values,
  selected: selected,
  labelOf: (c) => c.label,
  subtitleOf: (c) => c.province,
);
