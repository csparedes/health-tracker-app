import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:health_tracker_app/blocs/blocs.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/repositories/repositories.dart';
import 'package:health_tracker_app/screens/main_navigation_screen.dart';

/// Comprehensive end-to-end integration test covering complete user workflows
void main() {
  group('End-to-End Integration Tests', () {
    late SQLiteHealthDatabase database;
    late LocalHealthRepository repository;
    late HealthTrackingBloc bloc;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create a new in-memory database for each test
      database = SQLiteHealthDatabase(customPath: ':memory:');
      await database.initialize();
      repository = LocalHealthRepository(database);
      bloc = HealthTrackingBloc(repository);
    });

    tearDown(() async {
      await bloc.close();
      await database.close();
    });

    group('Complete User Workflows', () {
      testWidgets('should complete full workflow: home -> entry -> history -> details', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const MainNavigationScreen(),
            ),
          ),
        );

        // Step 1: Start on home screen
        expect(find.text('Bienvenido a Health Tracker'), findsOneWidget);
        expect(find.text('Registro Rápido'), findsOneWidget);

        // Step 2: Navigate to data entry via quick entry (Glucosa)
        await tester.tap(find.text('Glucosa'));
        await tester.pumpAndSettle();

        // Should be on data entry screen with glucose pre-selected
        expect(find.text('Registrar Datos de Salud'), findsOneWidget);
        expect(find.text('mg/dL'), findsWidgets);

        // Step 3: Enter glucose value
        await tester.enterText(find.byType(TextFormField).first, '125.5');
        await tester.enterText(find.byType(TextFormField).last, 'Morning reading after breakfast');

        // Step 4: Save the record
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Should show success message and clear form
        expect(find.text('Nivel de glucosa guardado exitosamente'), findsOneWidget);

        // Step 5: Navigate to history screen
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();

        // Should show the saved record
        expect(find.text('Historial de Salud'), findsOneWidget);
        expect(find.text('125.5 mg/dL'), findsOneWidget);
        expect(find.text('Morning reading after breakfast'), findsOneWidget);

        // Step 6: Tap on record for details
        await tester.tap(find.text('125.5 mg/dL'));
        await tester.pumpAndSettle();

        // Should show record details dialog
        expect(find.text('Glucosa'), findsWidgets);
        expect(find.text('125.5 mg/dL'), findsWidgets);
        expect(find.text('Morning reading after breakfast'), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Cerrar'));
        await tester.pumpAndSettle();

        // Step 7: Go back to home and verify recent data shows
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();

        // Should show recent measurement on home screen
        expect(find.text('125.5 mg/dL'), findsOneWidget);
      });

      testWidgets('should handle multiple metric types in complete workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const MainNavigationScreen(),
            ),
          ),
        );

        // Add glucose record
        await tester.tap(find.text('Glucosa'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '110.0');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Add waist diameter record
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Diámetro de Cintura'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '85.0');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Add body weight record
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Peso Corporal'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '70.5');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Go to history and verify all records
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();

        expect(find.text('110.0 mg/dL'), findsOneWidget);
        expect(find.text('85.0 cm'), findsOneWidget);
        expect(find.text('70.5 kg'), findsOneWidget);

        // Test filtering
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Glucosa'));
        await tester.pumpAndSettle();

        // Should only show glucose records
        expect(find.text('110.0 mg/dL'), findsOneWidget);
        expect(find.text('85.0 cm'), findsNothing);
        expect(find.text('70.5 kg'), findsNothing);

        // Clear filter
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Todos los registros'));
        await tester.pumpAndSettle();

        // Should show all records again
        expect(find.text('110.0 mg/dL'), findsOneWidget);
        expect(find.text('85.0 cm'), findsOneWidget);
        expect(find.text('70.5 kg'), findsOneWidget);
      });

      testWidgets('should handle validation errors in complete workflow', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const MainNavigationScreen(),
            ),
          ),
        );

        // Navigate to data entry
        await tester.tap(find.text('Glucosa'));
        await tester.pumpAndSettle();

        // Try to save without entering value
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('Por favor ingresa'), findsOneWidget);

        // Enter invalid value (negative)
        await tester.enterText(find.byType(TextFormField).first, '-50');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('El valor debe ser mayor que cero'), findsOneWidget);

        // Enter out of range value
        await tester.enterText(find.byType(TextFormField).first, '2000');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Should show range validation error
        expect(find.textContaining('debe estar entre'), findsOneWidget);

        // Enter valid value
        await tester.enterText(find.byType(TextFormField).first, '120.0');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Should succeed
        expect(find.text('Nivel de glucosa guardado exitosamente'), findsOneWidget);

        // Verify record was saved by checking history
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();
        expect(find.text('120.0 mg/dL'), findsOneWidget);
      });
    });

    group('Navigation and State Management', () {
      testWidgets('should maintain state across tab switches', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const MainNavigationScreen(),
            ),
          ),
        );

        // Add a record first
        await tester.tap(find.text('Glucosa'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '100.0');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Switch to history
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();
        expect(find.text('100.0 mg/dL'), findsOneWidget);

        // Switch back to home
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();
        expect(find.text('Bienvenido a Health Tracker'), findsOneWidget);

        // Switch to entry
        await tester.tap(find.text('Registrar'));
        await tester.pumpAndSettle();
        expect(find.text('Registrar Datos de Salud'), findsOneWidget);

        // Switch back to history - data should still be there
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();
        expect(find.text('100.0 mg/dL'), findsOneWidget);
      });

      testWidgets('should handle empty states correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const MainNavigationScreen(),
            ),
          ),
        );

        // Check empty history state
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();

        expect(find.text('No hay registros de salud'), findsOneWidget);
        expect(find.text('Comienza registrando tus primeras mediciones de salud'), findsOneWidget);
        expect(find.text('Agregar Primer Registro'), findsOneWidget);

        // Tap "Agregar Primer Registro" should go back to home
        await tester.tap(find.text('Agregar Primer Registro'));
        await tester.pumpAndSettle();
        expect(find.text('Bienvenido a Health Tracker'), findsOneWidget);

        // Check home screen shows no recent data
        expect(find.text('Sin registros'), findsWidgets);
      });
    });

    group('Error Handling and Recovery', () {
      testWidgets('should handle and recover from errors gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const MainNavigationScreen(),
            ),
          ),
        );

        // Test form validation recovery
        await tester.tap(find.text('Glucosa'));
        await tester.pumpAndSettle();

        // Enter invalid value
        await tester.enterText(find.byType(TextFormField).first, '-100');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Should show error
        expect(find.textContaining('El valor debe ser mayor que cero'), findsOneWidget);

        // Correct the value
        await tester.enterText(find.byType(TextFormField).first, '120.0');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Should succeed
        expect(find.text('Nivel de glucosa guardado exitosamente'), findsOneWidget);

        // Verify the app continues to work normally
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();
        expect(find.text('120.0 mg/dL'), findsOneWidget);
      });

      testWidgets('should handle refresh operations correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const MainNavigationScreen(),
            ),
          ),
        );

        // Add some data
        await tester.tap(find.text('Glucosa'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '95.0');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Go to history
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();

        // Test pull-to-refresh
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pumpAndSettle();

        // Data should still be there after refresh
        expect(find.text('95.0 mg/dL'), findsOneWidget);

        // Go to home and test refresh button
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();

        // Recent data should still be displayed
        expect(find.text('95.0 mg/dL'), findsOneWidget);
      });
    });

    group('Data Consistency and Integrity', () {
      testWidgets('should maintain data consistency across all screens', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const MainNavigationScreen(),
            ),
          ),
        );

        // Add multiple records of different types
        final testData = [
          {'type': 'Glucosa', 'value': '110.0', 'unit': 'mg/dL'},
          {'type': 'Diámetro de Cintura', 'value': '85.0', 'unit': 'cm'},
          {'type': 'Peso Corporal', 'value': '70.5', 'unit': 'kg'},
        ];

        for (final data in testData) {
          await tester.tap(find.text('Inicio'));
          await tester.pumpAndSettle();
          await tester.tap(find.text(data['type']!));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextFormField).first, data['value']!);
          await tester.tap(find.text('Guardar Registro'));
          await tester.pumpAndSettle();
        }

        // Verify data consistency on home screen
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();

        for (final data in testData) {
          expect(find.text('${data['value']} ${data['unit']}'), findsOneWidget);
        }

        // Verify data consistency on history screen
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();

        for (final data in testData) {
          expect(find.text('${data['value']} ${data['unit']}'), findsOneWidget);
        }

        // Verify record counts are correct
        expect(find.text('1'), findsNWidgets(3)); // Each type should have count of 1
      });

      testWidgets('should handle concurrent operations correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: bloc,
              child: const MainNavigationScreen(),
            ),
          ),
        );

        // Add a record
        await tester.tap(find.text('Glucosa'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '100.0');
        await tester.tap(find.text('Guardar Registro'));
        await tester.pumpAndSettle();

        // Quickly switch between tabs while data is being processed
        await tester.tap(find.text('Historial'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Inicio'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Registrar'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();

        // Data should still be consistent
        expect(find.text('100.0 mg/dL'), findsOneWidget);
      });
    });
  });
}