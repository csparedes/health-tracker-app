import '../database/database.dart';
import '../models/models.dart';
import 'health_repository.dart';

/// Local implementation of HealthRepository using SQLite database
class LocalHealthRepository implements HealthRepository {
  final HealthDatabase _database;

  const LocalHealthRepository(this._database);

  @override
  Future<void> saveHealthRecord(HealthRecord record) async {
    try {
      // Validate the record before saving
      if (!record.isValid()) {
        throw ValidationException(_getValidationErrorMessage(record));
      }

      // Save to database
      await _database.insertHealthRecord(record);
    } on ValidationException {
      rethrow; // Re-throw validation exceptions as-is
    } catch (e) {
      throw RepositoryException('Failed to save health record', Exception(e.toString()));
    }
  }

  @override
  Future<List<HealthRecord>> getHealthHistory() async {
    try {
      return await _database.getAllRecords();
    } catch (e) {
      throw RepositoryException('Failed to retrieve health history', Exception(e.toString()));
    }
  }

  @override
  Future<List<HealthRecord>> getHistoryByType(HealthMetricType type) async {
    try {
      return await _database.getRecordsByType(type);
    } catch (e) {
      throw RepositoryException('Failed to retrieve health history by type', Exception(e.toString()));
    }
  }

  @override
  Future<int> getRecordCountByType(HealthMetricType type) async {
    try {
      if (_database is SQLiteHealthDatabase) {
        return await _database.getRecordCountByType(type);
      }
      // Fallback for other database implementations
      final records = await _database.getRecordsByType(type);
      return records.length;
    } catch (e) {
      throw RepositoryException('Failed to get record count by type', Exception(e.toString()));
    }
  }

  @override
  Future<HealthRecord?> getMostRecentRecordByType(HealthMetricType type) async {
    try {
      if (_database is SQLiteHealthDatabase) {
        return await _database.getMostRecentRecordByType(type);
      }
      // Fallback for other database implementations
      final records = await _database.getRecordsByType(type);
      return records.isNotEmpty ? records.first : null;
    } catch (e) {
      throw RepositoryException('Failed to get most recent record by type', Exception(e.toString()));
    }
  }

  @override
  Future<List<HealthRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    HealthMetricType? type,
  }) async {
    try {
      if (_database is SQLiteHealthDatabase) {
        return await _database.getRecordsByDateRange(
          startDate,
          endDate,
          type: type,
        );
      }
      // Fallback for other database implementations
      final allRecords = type != null 
          ? await _database.getRecordsByType(type)
          : await _database.getAllRecords();
      
      return allRecords.where((record) {
        return record.timestamp.isAfter(startDate.subtract(const Duration(milliseconds: 1))) &&
               record.timestamp.isBefore(endDate.add(const Duration(milliseconds: 1)));
      }).toList();
    } catch (e) {
      throw RepositoryException('Failed to get records by date range', Exception(e.toString()));
    }
  }

  @override
  Future<void> deleteRecord(int id) async {
    try {
      await _database.deleteRecord(id);
    } catch (e) {
      throw RepositoryException('Failed to delete health record', Exception(e.toString()));
    }
  }

  /// Generate a detailed validation error message
  String _getValidationErrorMessage(HealthRecord record) {
    final errors = <String>[];

    // Check if value is positive
    if (record.value <= 0) {
      errors.add('El valor debe ser mayor que cero');
    }

    // Check if value is within valid range
    final range = record.type.validationRange;
    if (record.value < range.min || record.value > range.max) {
      errors.add('El valor debe estar entre ${range.min} y ${range.max} ${record.type.unit}');
    }

    // Check if timestamp is not in the future (with 1 minute tolerance)
    final now = DateTime.now();
    final oneMinuteFromNow = now.add(const Duration(minutes: 1));
    if (record.timestamp.isAfter(oneMinuteFromNow)) {
      errors.add('La fecha no puede ser en el futuro');
    }

    if (errors.isEmpty) {
      return 'Registro de salud inválido';
    }

    return errors.join(', ');
  }

  /// Validate a health record and return validation errors
  List<String> validateHealthRecord(HealthRecord record) {
    final errors = <String>[];

    // Check if value is positive
    if (record.value <= 0) {
      errors.add('El valor debe ser mayor que cero');
    }

    // Check if value is within valid range for the metric type
    final range = record.type.validationRange;
    if (record.value < range.min || record.value > range.max) {
      errors.add('El valor debe estar entre ${range.min} y ${range.max} ${record.type.unit}');
    }

    // Check if timestamp is not in the future (with 1 minute tolerance)
    final now = DateTime.now();
    final oneMinuteFromNow = now.add(const Duration(minutes: 1));
    if (record.timestamp.isAfter(oneMinuteFromNow)) {
      errors.add('La fecha no puede ser en el futuro');
    }

    return errors;
  }

  /// Check if a health record is valid
  bool isValidHealthRecord(HealthRecord record) {
    return validateHealthRecord(record).isEmpty;
  }
}