import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apex_app/screens/complaint_management_screen.dart';

void main() {
  testWidgets('complaint management actions are visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ComplaintManagementScreen()),
    );

    expect(find.text('Complaint Management'), findsOneWidget);
    expect(find.text('View Complaints'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
  });
}
