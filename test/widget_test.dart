import 'package:expense_tracker/data/memory_expense_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows expense tracker title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ExpenseTrackerApp(repository: MemoryExpenseRepository()),
    );
    await tester.pump();
    expect(find.text('Expense Tracker'), findsOneWidget);
  });
}
