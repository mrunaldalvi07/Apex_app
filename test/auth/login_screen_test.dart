import 'package:apex_app/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('login screen fits a $width dp mobile width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width * 3, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      expect(find.text('Welcome to APEX'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
