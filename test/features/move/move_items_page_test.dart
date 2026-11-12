import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/core/theme/app_theme.dart';
import 'package:imuka/features/move/data/repositories/mock_move_repositories.dart';
import 'package:imuka/features/move/presentation/cubit/move_plan_cubit.dart';
import 'package:imuka/features/move/presentation/pages/move_items_page.dart';

void main() {
  Future<MovePlanCubit> pumpPage(WidgetTester tester) async {
    final cubit = MovePlanCubit(MockMoveItemRepository(latency: Duration.zero));
    await tester.runAsync(cubit.load);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(theme: AppTheme.light, home: const MoveItemsPage()),
      ),
    );
    return cubit;
  }

  testWidgets('lists the items with the upfront estimate', (tester) async {
    await pumpPage(tester);

    expect(find.text('Your items (6)'), findsOneWidget);
    expect(find.text('Boxes (medium)'), findsOneWidget);
    expect(find.text('RWF 220,000'), findsOneWidget);
  });

  testWidgets('adding an item updates the list and the price together', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextFormField), 'Bicycle');
    await tester.tap(find.byTooltip('Add item'));
    await tester.pumpAndSettle();

    expect(find.text('Your items (7)'), findsOneWidget);
    expect(find.text('Bicycle'), findsOneWidget);
    expect(find.text('RWF 228,000'), findsOneWidget);
  });

  testWidgets('an empty item name shows a validation message', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Add item'));
    await tester.pump();

    expect(find.text('Type the name of the item first.'), findsOneWidget);
    expect(find.text('Your items (6)'), findsOneWidget);
  });

  testWidgets('the + button increases a quantity', (tester) async {
    final cubit = await pumpPage(tester);

    await tester.ensureVisible(find.byTooltip('Add one TV'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add one TV'));
    await tester.pumpAndSettle();

    expect(cubit.state.items.last.quantity, 2);
    expect(find.text('RWF 230,000'), findsOneWidget);
  });
}
