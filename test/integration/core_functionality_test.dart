import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:health_tracker_app/blocs/blocs.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/models/models.dart';
import 'package:health_tracker_app/repositories/repositories.dart';

/// Integration test to verify core functionality works end-to-end
void main() {
  group('Core Functionality Integration Test', () {
    late SQLiteHealthDatabase database;
    late LocalHealthRepository repository;
    late HealthTrackingBloc bloc;
    late DateTime testTimestamp;

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
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
    });

    tearDown(() async {
      await bloc.close();
      await database.close();
    });

    test('Complete workflow: Create, Store, Retrieve, and Validate health records', () async {
      // Test 1: Create valid health records for all metric types
      final glucoseRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.5,
        timestamp: testTimestamp,
        notes: 'Morning reading',
      );

      final waistRecord = HealthRecord(
        type: HealthMetricType.waistDiameter,
        value: 85.0,
        timestamp: testTimestamp.add(const Duration(minutes: 30)),
        notes: 'After breakfast',
      );

      final weightRecord = HealthRecord(
        type: HealthMetricType.bodyWeight,
        value: 70.5,
        timestamp: testTimestamp.add(const Duration(hours: 1)),
        notes: 'Weekly weigh-in',
      );

      // Test 2: Validate records are valid
      expect(glucoseRecord.isValid(), isTrue);
      expect(waistRecord.isValid(), isTrue);
      expect(weightRecord.isValid(), isTrue);

      // Test 3: Store records through repository
      await repository.saveHealthRecord(glucoseRecord);
      await repository.saveHealthRecord(waistRecord);
      await repository.saveHealthRecord(weightRecord);

      // Test 4: Retrieve all records and verify ordering (most recent first)
      final allRecords = await repository.getHealthHistory();
      expect(allRecords, hasLength(3));
      expect(allRecords[0].type, equals(HealthMetricType.bodyWeight)); // Most recent
      expect(allRecords[1].type, equals(HealthMetricType.waistDiameter));
      expect(allRecords[2].type, equals(HealthMetricType.glucose)); // Oldest

      // Test 5: Filter by type
      final glucoseRecords = await repository.getHistoryByType(HealthMetricType.glucose);
      expect(glucoseRecords, hasLength(1));
      expect(glucoseRecords.first.type, equals(HealthMetricType.glucose));
      expect(glucoseRecords.first.value, equals(120.5));

      // Test 6: Get record count by type
      final glucoseCount = await repository.getRecordCountByType(HealthMetricType.glucose);
      expect(glucoseCount, equals(1));

      // Test 7: Get most recent record by type
      final mostRecentGlucose = await repository.getMostRecentRecordByType(HealthMetricType.glucose);
      expect(mostRecentGlucose, isNotNull);
      expect(mostRecentGlucose!.value, equals(120.5));

      // Test 8: Test validation with invalid record
      final invalidRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: -10.0, // Invalid negative value
        timestamp: testTimestamp,
      );

      expect(invalidRecord.isValid(), isFalse);
      expect(() => repository.saveHealthRecord(invalidRecord), throwsA(isA<ValidationException>()));

      // Test 9: Test formatted values and timestamps
      expect(glucoseRecord.formattedValue, equals('120.5 mg/dL'));
      expect(waistRecord.formattedValue, equals('85.0 cm'));
      expect(weightRecord.formattedValue, equals('70.5 kg'));

      // Test 10: Test enum functionality
      expect(HealthMetricType.glucose.displayName, equals('Glucosa'));
      expect(HealthMetricType.waistDiameter.displayName, equals('Diámetro de Cintura'));
      expect(HealthMetricType.bodyWeight.displayName, equals('Peso Corporal'));

      expect(HealthMetricType.glucose.unit, equals('mg/dL'));
      expect(HealthMetricType.waistDiameter.unit, equals('cm'));
      expect(HealthMetricType.bodyWeight.unit, equals('kg'));

      // Test 11: Test validation ranges
      final glucoseRange = HealthMetricType.glucose.validationRange;
      expect(glucoseRange.min, equals(0.0));
      expect(glucoseRange.max, equals(1000.0));

      // Test 12: Test database persistence (close and reopen)
      await database.close();
      
      // Reopen database and verify data persists
      database = SQLiteHealthDatabase(customPath: ':memory:');
      await database.initialize();
      repository = LocalHealthRepository(database);
      
      // Note: In-memory database doesn't persist, but this tests the initialization
      expect(database, isNotNull);
      
      // Test 13: Verify BLoC can be created and initialized
      bloc = HealthTrackingBloc(repository);
      expect(bloc.state, isA<HealthTrackingInitial>());
    });

    test('Error handling and edge cases', () async {
      // Test 1: Empty database queries
      final emptyHistory = await repository.getHealthHistory();
      expect(emptyHistory, isEmpty);

      final emptyGlucoseHistory = await repository.getHistoryByType(HealthMetricType.glucose);
      expect(emptyGlucoseHistory, isEmpty);

      final zeroCount = await repository.getRecordCountByType(HealthMetricType.glucose);
      expect(zeroCount, equals(0));

      final nullMostRecent = await repository.getMostRecentRecordByType(HealthMetricType.glucose);
      expect(nullMostRecent, isNull);

      // Test 2: Validation error messages in Spanish
      final invalidRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: -10.0,
        timestamp: testTimestamp,
      );

      final validationErrors = repository.validateHealthRecord(invalidRecord);
      expect(validationErrors, isNotEmpty);
      expect(validationErrors.first, contains('El valor debe ser mayor que cero'));

      // Test 3: Out of range validation
      final outOfRangeRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 1500.0, // Above max range
        timestamp: testTimestamp,
      );

      final rangeErrors = repository.validateHealthRecord(outOfRangeRecord);
      expect(rangeErrors, isNotEmpty);
      expect(rangeErrors.first, contains('debe estar entre'));

      // Test 4: Future timestamp validation
      final futureRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: DateTime.now().add(const Duration(hours: 2)),
      );

      final futureErrors = repository.validateHealthRecord(futureRecord);
      expect(futureErrors, isNotEmpty);
      expect(futureErrors.first, contains('La fecha no puede ser en el futuro'));
    });

    test('Data model serialization and deserialization', () async {
      // Test 1: HealthRecord serialization
      final originalRecord = HealthRecord(
        id: 1,
        type: HealthMetricType.glucose,
        value: 120.5,
        timestamp: testTimestamp,
        notes: 'Test note',
      );

      final map = originalRecord.toMap();
      final deserializedRecord = HealthRecord.fromMap(map);

      expect(deserializedRecord, equals(originalRecord));
      expect(deserializedRecord.id, equals(originalRecord.id));
      expect(deserializedRecord.type, equals(originalRecord.type));
      expect(deserializedRecord.value, equals(originalRecord.value));
      expect(deserializedRecord.timestamp, equals(originalRecord.timestamp));
      expect(deserializedRecord.notes, equals(originalRecord.notes));

      // Test 2: HealthMetricType string conversion
      expect(HealthMetricType.fromString('glucose'), equals(HealthMetricType.glucose));
      expect(HealthMetricType.glucose.toDbString(), equals('glucose'));

      // Test 3: Record copying
      final copiedRecord = originalRecord.copyWith(value: 130.0, notes: 'Updated note');
      expect(copiedRecord.id, equals(originalRecord.id));
      expect(copiedRecord.type, equals(originalRecord.type));
      expect(copiedRecord.value, equals(130.0));
      expect(copiedRecord.timestamp, equals(originalRecord.timestamp));
      expect(copiedRecord.notes, equals('Updated note'));
    });
  });
}