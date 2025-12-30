import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_tracker_app/main.dart';

void main() {
  testWidgets('Health Tracker app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HealthTrackerApp());

    // Verify that the app shows the welcome message.
    expect(find.text('Bienvenido a Health Tracker'), findsOneWidget);
    expect(find.text('Registra y monitorea tus datos de salud'), findsOneWidget);
    expect(find.text('La aplicación está en desarrollo...'), findsOneWidget);

    // Verify that the health icon is present.
    expect(find.byIcon(Icons.health_and_safety), findsOneWidget);
  });
}
