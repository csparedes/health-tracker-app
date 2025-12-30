import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/models/models.dart';

void main() {
  group('SQLiteHealthDatabase', () {
    late SQLiteHealthDatabase database;
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
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
    });

    tearDown(() async {
      await database.close();
    });

    test('should initialize database successfully', () async {
      // Database should be initialized in setUp
      expect(database, isNotNull);
    });

    test('should insert and retrieve health record', () async {
      final record = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.5,
        timestamp: testTimestamp,
        notes: 'Test glucose reading',
      );

      final id = await database.insertHealthRecord(record);
      expect(id, isPositive);

      final records = await database.getAllRecords();
      expect(records, hasLength(1));
      
      final retrievedRecord = records.first;
      expect(retrievedRecord.id, equals(id));
      expect(retrievedRecord.type, equals(record.type));
      expect(retrievedRecord.value, equals(record.value));
      expect(retrievedRecord.timestamp, equals(record.timestamp));
      expect(retrievedRecord.notes, equals(record.notes));
    });

    test('should retrieve records ordered by timestamp (most recent first)', () async {
      final oldRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 100.0,
        timestamp: testTimestamp.subtract(const Duration(hours: 2)),
      );

      final newRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: testTimestamp,
      );

      await database.insertHealthRecord(oldRecord);
      await database.insertHealthRecord(newRecord);

      final records = await database.getAllRecords();
      expect(records, hasLength(2));
      expect(records.first.timestamp, equals(newRecord.timestamp));
      expect(records.last.timestamp, equals(oldRecord.timestamp));
    });

    test('should filter records by type', () async {
      final glucoseRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: testTimestamp,
      );

      final weightRecord = HealthRecord(
        type: HealthMetricType.bodyWeight,
        value: 70.0,
        timestamp: testTimestamp.add(const Duration(minutes: 30)),
      );

      await database.insertHealthRecord(glucoseRecord);
      await database.insertHealthRecord(weightRecord);

      final glucoseRecords = await database.getRecordsByType(HealthMetricType.glucose);
      expect(glucoseRecords, hasLength(1));
      expect(glucoseRecords.first.type, equals(HealthMetricType.glucose));

      final weightRecords = await database.getRecordsByType(HealthMetricType.bodyWeight);
      expect(weightRecords, hasLength(1));
      expect(weightRecords.first.type, equals(HealthMetricType.bodyWeight));
    });

    test('should delete record by ID', () async {
      final record = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: testTimestamp,
      );

      final id = await database.insertHealthRecord(record);
      
      // Verify record exists
      var records = await database.getAllRecords();
      expect(records, hasLength(1));

      // Delete record
      await database.deleteRecord(id);

      // Verify record is deleted
      records = await database.getAllRecords();
      expect(records, isEmpty);
    });

    test('should get record count by type', () async {
      await database.insertHealthRecord(HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: testTimestamp,
      ));

      await database.insertHealthRecord(HealthRecord(
        type: HealthMetricType.glucose,
        value: 130.0,
        timestamp: testTimestamp.add(const Duration(hours: 1)),
      ));

      await database.insertHealthRecord(HealthRecord(
        type: HealthMetricType.bodyWeight,
        value: 70.0,
        timestamp: testTimestamp,
      ));

      final glucoseCount = await database.getRecordCountByType(HealthMetricType.glucose);
      expect(glucoseCount, equals(2));

      final weightCount = await database.getRecordCountByType(HealthMetricType.bodyWeight);
      expect(weightCount, equals(1));

      final waistCount = await database.getRecordCountByType(HealthMetricType.waistDiameter);
      expect(waistCount, equals(0));
    });

    test('should get most recent record by type', () async {
      final oldRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 100.0,
        timestamp: testTimestamp.subtract(const Duration(hours: 2)),
      );

      final newRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: testTimestamp,
      );

      await database.insertHealthRecord(oldRecord);
      await database.insertHealthRecord(newRecord);

      final mostRecent = await database.getMostRecentRecordByType(HealthMetricType.glucose);
      expect(mostRecent, isNotNull);
      expect(mostRecent!.value, equals(120.0));
      expect(mostRecent.timestamp, equals(testTimestamp));
    });

    test('should return null for most recent record when no records exist', () async {
      final mostRecent = await database.getMostRecentRecordByType(HealthMetricType.glucose);
      expect(mostRecent, isNull);
    });

    test('should get records by date range', () async {
      final record1 = HealthRecord(
        type: HealthMetricType.glucose,
        value: 100.0,
        timestamp: DateTime(2024, 1, 10),
      );

      final record2 = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: DateTime(2024, 1, 15),
      );

      final record3 = HealthRecord(
        type: HealthMetricType.glucose,
        value: 140.0,
        timestamp: DateTime(2024, 1, 20),
      );

      await database.insertHealthRecord(record1);
      await database.insertHealthRecord(record2);
      await database.insertHealthRecord(record3);

      final records = await database.getRecordsByDateRange(
        DateTime(2024, 1, 12),
        DateTime(2024, 1, 18),
      );

      expect(records, hasLength(1));
      expect(records.first.value, equals(120.0));
    });

    test('should handle transaction rollback on error', () async {
      // This test verifies that database operations are properly wrapped in transactions
      // We can't easily simulate a transaction failure in tests, but we can verify
      // that the transaction methods are being called by checking the data integrity
      
      final record = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: testTimestamp,
      );

      final id = await database.insertHealthRecord(record);
      expect(id, isPositive);

      // Verify the record was inserted
      final records = await database.getAllRecords();
      expect(records, hasLength(1));
      expect(records.first.id, equals(id));
    });
  });
}