import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:health_tracker_app/blocs/blocs.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/models/models.dart';
import 'package:health_tracker_app/repositories/repositories.dart';

void main() {
  group('HealthTrackingBloc', () {
    late HealthTrackingBloc bloc;
    late LocalHealthRepository repository;
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
      repository = LocalHealthRepository(database);
      bloc = HealthTrackingBloc(repository);
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
    });

    tearDown(() async {
      await bloc.close();
      await database.close();
    });

    test('initial state is HealthTrackingInitial', () {
      expect(bloc.state, equals(const HealthTrackingInitial()));
    });

    group('AddHealthRecord', () {
      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [HealthTrackingLoading, HealthRecordAdded, HealthTrackingLoading, HealthTrackingLoaded] when valid record is added',
        build: () => bloc,
        act: (bloc) => bloc.add(AddHealthRecord(HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.5,
          timestamp: testTimestamp,
          notes: 'Test glucose reading',
        ))),
        expect: () => [
          const HealthTrackingLoading(),
          isA<HealthRecordAdded>()
              .having((state) => state.addedRecord.type, 'type', HealthMetricType.glucose)
              .having((state) => state.addedRecord.value, 'value', 120.5)
              .having((state) => state.successMessage, 'message', 'Nivel de glucosa guardado exitosamente'),
          const HealthTrackingLoading(),
          isA<HealthTrackingLoaded>()
              .having((state) => state.records.length, 'records length', 1),
        ],
      );

      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [HealthTrackingLoading, HealthTrackingValidationError] when invalid record is added',
        build: () => bloc,
        act: (bloc) => bloc.add(AddHealthRecord(HealthRecord(
          type: HealthMetricType.glucose,
          value: -10.0, // Invalid negative value
          timestamp: testTimestamp,
        ))),
        expect: () => [
          const HealthTrackingLoading(),
          isA<HealthTrackingValidationError>()
              .having((state) => state.errors, 'errors', contains('El valor debe ser mayor que cero')),
        ],
      );

      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits correct success message for different metric types',
        build: () => bloc,
        act: (bloc) => bloc.add(AddHealthRecord(HealthRecord(
          type: HealthMetricType.bodyWeight,
          value: 70.0,
          timestamp: testTimestamp,
        ))),
        expect: () => [
          const HealthTrackingLoading(),
          isA<HealthRecordAdded>()
              .having((state) => state.successMessage, 'message', 'Peso corporal guardado exitosamente'),
          const HealthTrackingLoading(),
          isA<HealthTrackingLoaded>(),
        ],
      );
    });

    group('LoadHistory', () {
      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [HealthTrackingLoading, HealthTrackingLoaded] with empty list when no records exist',
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadHistory()),
        expect: () => [
          const HealthTrackingLoading(),
          isA<HealthTrackingLoaded>()
              .having((state) => state.records, 'records', isEmpty)
              .having((state) => state.currentFilter, 'currentFilter', isNull),
        ],
      );

      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [HealthTrackingLoading, HealthTrackingLoaded] with records when records exist',
        build: () => bloc,
        setUp: () async {
          // Add a record first
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 120.0,
            timestamp: testTimestamp,
          ));
        },
        act: (bloc) => bloc.add(const LoadHistory()),
        expect: () => [
          const HealthTrackingLoading(),
          isA<HealthTrackingLoaded>()
              .having((state) => state.records.length, 'records length', 1),
        ],
      );
    });

    group('FilterByType', () {
      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [HealthTrackingLoading, HealthTrackingLoaded] with filtered records',
        build: () => bloc,
        setUp: () async {
          // Add records of different types
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 120.0,
            timestamp: testTimestamp,
          ));
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.bodyWeight,
            value: 70.0,
            timestamp: testTimestamp.add(const Duration(minutes: 30)),
          ));
        },
        act: (bloc) => bloc.add(const FilterByType(HealthMetricType.glucose)),
        expect: () => [
          const HealthTrackingLoading(),
          isA<HealthTrackingLoaded>()
              .having((state) => state.records.length, 'records length', 1)
              .having((state) => state.records.first.type, 'first record type', HealthMetricType.glucose)
              .having((state) => state.currentFilter, 'currentFilter', HealthMetricType.glucose),
        ],
      );

      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [HealthTrackingLoading, HealthTrackingLoaded] with all records when filter is null',
        build: () => bloc,
        setUp: () async {
          // Add records of different types
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 120.0,
            timestamp: testTimestamp,
          ));
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.bodyWeight,
            value: 70.0,
            timestamp: testTimestamp.add(const Duration(minutes: 30)),
          ));
        },
        act: (bloc) => bloc.add(const FilterByType(null)),
        expect: () => [
          const HealthTrackingLoading(),
          isA<HealthTrackingLoaded>()
              .having((state) => state.records.length, 'records length', 2)
              .having((state) => state.currentFilter, 'currentFilter', isNull),
        ],
      );
    });

    group('LoadRecordsByDateRange', () {
      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [HealthTrackingLoading, HealthTrackingLoaded] with records in date range',
        build: () => bloc,
        setUp: () async {
          // Add records with different dates
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 100.0,
            timestamp: DateTime(2024, 1, 10),
          ));
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 120.0,
            timestamp: DateTime(2024, 1, 15),
          ));
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 140.0,
            timestamp: DateTime(2024, 1, 20),
          ));
        },
        act: (bloc) => bloc.add(LoadRecordsByDateRange(
          DateTime(2024, 1, 12),
          DateTime(2024, 1, 18),
        )),
        expect: () => [
          const HealthTrackingLoading(),
          isA<HealthTrackingLoaded>()
              .having((state) => state.records.length, 'records length', 1)
              .having((state) => state.records.first.value, 'first record value', 120.0),
        ],
      );
    });

    group('DeleteHealthRecord', () {
      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [HealthTrackingLoading, HealthRecordDeleted, HealthTrackingLoading, HealthTrackingLoaded] when record is deleted',
        build: () => bloc,
        setUp: () async {
          // Add a record first
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 120.0,
            timestamp: testTimestamp,
          ));
        },
        act: (bloc) async {
          // Get the record ID first
          final records = await repository.getHealthHistory();
          final recordId = records.first.id!;
          bloc.add(DeleteHealthRecord(recordId));
        },
        expect: () => [
          const HealthTrackingLoading(),
          isA<HealthRecordDeleted>()
              .having((state) => state.successMessage, 'message', 'Registro eliminado exitosamente'),
          const HealthTrackingLoading(),
          isA<HealthTrackingLoaded>(),
        ],
      );
    });

    group('GetRecordCountByType', () {
      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [RecordCountLoaded] with correct count',
        build: () => bloc,
        setUp: () async {
          // Add records of different types
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 120.0,
            timestamp: testTimestamp,
          ));
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 130.0,
            timestamp: testTimestamp.add(const Duration(hours: 1)),
          ));
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.bodyWeight,
            value: 70.0,
            timestamp: testTimestamp,
          ));
        },
        act: (bloc) => bloc.add(const GetRecordCountByType(HealthMetricType.glucose)),
        expect: () => [
          isA<RecordCountLoaded>()
              .having((state) => state.type, 'type', HealthMetricType.glucose)
              .having((state) => state.count, 'count', 2),
        ],
      );
    });

    group('GetMostRecentRecordByType', () {
      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [MostRecentRecordLoaded] with most recent record',
        build: () => bloc,
        setUp: () async {
          // Add records with different timestamps
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 100.0,
            timestamp: testTimestamp.subtract(const Duration(hours: 2)),
          ));
          await repository.saveHealthRecord(HealthRecord(
            type: HealthMetricType.glucose,
            value: 120.0,
            timestamp: testTimestamp,
          ));
        },
        act: (bloc) => bloc.add(const GetMostRecentRecordByType(HealthMetricType.glucose)),
        expect: () => [
          isA<MostRecentRecordLoaded>()
              .having((state) => state.type, 'type', HealthMetricType.glucose)
              .having((state) => state.record?.value, 'record value', 120.0),
        ],
      );

      blocTest<HealthTrackingBloc, HealthTrackingState>(
        'emits [MostRecentRecordLoaded] with null when no records exist',
        build: () => bloc,
        act: (bloc) => bloc.add(const GetMostRecentRecordByType(HealthMetricType.glucose)),
        expect: () => [
          isA<MostRecentRecordLoaded>()
              .having((state) => state.type, 'type', HealthMetricType.glucose)
              .having((state) => state.record, 'record', isNull),
        ],
      );
    });
  });
}