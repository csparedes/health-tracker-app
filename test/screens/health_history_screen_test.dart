import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:health_tracker_app/blocs/blocs.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/models/models.dart';
import 'package:health_tracker_app/repositories/repositories.dart';
import 'package:health_tracker_app/screens/health_history_screen.dart';

void main() {
  group('HealthHistoryScreen', () {
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

    testWidgets('should display empty state when no records exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const HealthHistoryScreen(),
          ),
        ),
      );

      // Wait for the initial load
      await tester.pump();

      // Should show empty state
      expect(find.text('No hay registros de salud'), findsOneWidget);
      expect(find.text('Comienza registrando tus primeras mediciones de salud'), findsOneWidget);
      expect(find.text('Agregar Primer Registro'), findsOneWidget);
    });

    testWidgets('should display filter button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const HealthHistoryScreen(),
          ),
        ),
      );

      // Should have filter button in app bar
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.text('Historial de Salud'), findsOneWidget);
    });

    testWidgets('should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const HealthHistoryScreen(),
          ),
        ),
      );

      // Should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando historial...'), findsOneWidget);
    });
  });
}