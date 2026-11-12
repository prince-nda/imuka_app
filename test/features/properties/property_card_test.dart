import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/features/properties/data/repositories/mock_property_repository.dart';
import 'package:imuka/features/properties/presentation/widgets/property_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  final repository = MockPropertyRepository(latency: Duration.zero);

  testWidgets('shows a verified listing like the Figma card', (tester) async {
    final property = (await tester.runAsync(
      () => repository.getProperty('kacyiru-modern'),
    ))!;
    await tester.pumpWidget(
      themed(PropertyCard(property: property, onTap: () {})),
    );

    expect(find.text('Kacyiru Modern Apartment'), findsOneWidget);
    expect(find.text('Apartment · Kacyiru, Gasabo'), findsOneWidget);
    expect(find.textContaining('RWF 450,000'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
  });

  testWidgets('flags listings whose checks are still pending', (tester) async {
    final property = (await tester.runAsync(
      () => repository.getProperty('nyamirambo-room'),
    ))!;
    var tapped = false;
    await tester.pumpWidget(
      themed(PropertyCard(property: property, onTap: () => tapped = true)),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Verified'), findsNothing);

    await tester.tap(find.byType(PropertyCard));
    expect(tapped, isTrue);
  });
}
