import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:health_tracker_app/blocs/blocs.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/models/models.dart';
import 'package:health_tracker_app/repositories/repositories.dart';
import 'package:health_tracker_app/screens/health_data_entry_screen.dart';

void main() {
  group('HealthDataEntryScreen', () {
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

    testWidgets('should display all health metric types', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const HealthDataEntryScreen(),
          ),
        ),
      );

      // Verify that all metric types are displayed
      expect(find.text('Glucosa'), findsOneWidget);
      expect(find.text('Diámetro de Cintura'), findsOneWidget);
      expect(find.text('Peso Corporal'), findsOneWidget);

      // Verify that the form elements are present
      expect(find.text('Registrar Datos de Salud'), findsOneWidget);
      expect(find.text('Tipo de Medición'), findsOneWidget);
      expect(find.text('Guardar Registro'), findsOneWidget);
    });

    testWidgets('should validate input fields correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const HealthDataEntryScreen(),
          ),
        ),
      );

      // Scroll to the save button to make it visible
      await tester.scrollUntilVisible(
        find.text('Guardar Registro'),
        500.0,
      );

      // Try to save without entering a value
      await tester.tap(find.text('Guardar Registro'));
      await tester.pump();

      // Should show validation error (the form validation will trigger)
      expect(find.textContaining('Por favor ingresa'), findsOneWidget);
    });

    testWidgets('should show appropriate units for each metric type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const HealthDataEntryScreen(),
          ),
        ),
      );

      // Default should be glucose (mg/dL)
      expect(find.text('mg/dL'), findsWidgets);

      // Select waist diameter
      await tester.tap(find.text('Diámetro de Cintura'));
      await tester.pump();

      // Should show cm unit
      expect(find.text('cm'), findsWidgets);

      // Select body weight
      await tester.tap(find.text('Peso Corporal'));
      await tester.pump();

      // Should show kg unit
      expect(find.text('kg'), findsWidgets);
    });

    testWidgets('should pre-select initial type when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const HealthDataEntryScreen(
              initialType: HealthMetricType.bodyWeight,
            ),
          ),
        ),
      );

      // Should have body weight pre-selected
      expect(find.text('kg'), findsWidgets);
      
      // The body weight radio button should be selected
      final bodyWeightRadio = tester.widget<RadioListTile<HealthMetricType>>(
        find.byWidgetPredicate((widget) => 
          widget is RadioListTile<HealthMetricType> && 
          widget.title is Text && 
          (widget.title as Text).data == 'Peso Corporal'
        ),
      );
      expect(bodyWeightRadio.groupValue, equals(HealthMetricType.bodyWeight));
    });
  });
}