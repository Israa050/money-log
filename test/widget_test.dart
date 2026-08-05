import 'package:flutter_test/flutter_test.dart';

import 'package:stockflow/core/service_locator.dart';
import 'package:stockflow/main.dart';
import 'package:stockflow/transactions/presentation/screens/transactions_screen.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    setupServiceLocator();
    await tester.pumpWidget(const MyApp());

    expect(find.byType(TransactionsScreen), findsOneWidget);
  });
}
