import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:health_tracker_app/blocs/blocs.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/repositories/repositories.dart';
import 'package:health_tracker_app/screens/main_navigation_screen.dart';

void main() {
  group('MainNavigationScreen', () {
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

    testWidgets('should display bottom navigation with three tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainNavigationScreen(),
          ),
        ),
      );

      // Should have bottom navigation bar with three tabs
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
    });

    testWidgets('should display home screen by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainNavigationScreen(),
          ),
        ),
      );

      // Should show home screen content
      expect(find.text('Health Tracker'), findsOneWidget);
      expect(find.text('Bienvenido a Health Tracker'), findsOneWidget);
      expect(find.text('Registro Rápido'), findsOneWidget);
    });

    testWidgets('should show quick entry options for all metric types', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainNavigationScreen(),
          ),
        ),
      );

      // Should show quick entry options for all metric types
      expect(find.text('Glucosa'), findsOneWidget);
      expect(find.text('Diámetro de Cintura'), findsOneWidget);
      expect(find.text('Peso Corporal'), findsOneWidget);
    });
  });
}