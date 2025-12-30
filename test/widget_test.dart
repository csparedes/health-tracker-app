import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:health_tracker_app/main.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/repositories/repositories.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Health Tracker app smoke test', (WidgetTester tester) async {
    // Create test database and repository
    final database = SQLiteHealthDatabase(customPath: ':memory:');
    await database.initialize();
    final repository = LocalHealthRepository(database);

    // Build our app and trigger a frame.
    await tester.pumpWidget(HealthTrackerApp(repository: repository));

    // Verify that the app shows the welcome message.
    expect(find.text('Bienvenido a Health Tracker'), findsOneWidget);
    expect(find.text('Registra y monitorea tus datos de salud de manera fácil y segura'), findsOneWidget);

    // Verify that the health icon is present.
    expect(find.byIcon(Icons.health_and_safety), findsOneWidget);

    // Verify that quick action buttons are present
    expect(find.text('Registrar Nuevos Datos'), findsOneWidget);
    expect(find.text('Ver Historial'), findsOneWidget);

    // Clean up
    await database.close();
  });
}
