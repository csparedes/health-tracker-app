import 'health_metric_type.dart';

/// Represents a single health measurement record
class HealthRecord {
  final int? id;
  final HealthMetricType type;
  final double value;
  final DateTime timestamp;
  final String? notes;

  const HealthRecord({
    this.id,
    required this.type,
    required this.value,
    required this.timestamp,
    this.notes,
  });

  /// Creates a HealthRecord from a database map
  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'] as int?,
      type: HealthMetricType.fromString(map['type'] as String),
      value: (map['value'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      notes: map['notes'] as String?,
    );
  }

  /// Converts the HealthRecord to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toDbString(),
      'value': value,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  /// Creates a copy of this HealthRecord with the given fields replaced
  HealthRecord copyWith({
    int? id,
    HealthMetricType? type,
    double? value,
    DateTime? timestamp,
    String? notes,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }

  /// Validates the health record according to business rules
  bool isValid() {
    // Check if value is positive
    if (value <= 0) return false;
    
    // Check if value is within the valid range for the metric type
    final range = type.validationRange;
    if (value < range.min || value > range.max) return false;
    
    // Check if timestamp is not in the future (with 1 minute tolerance)
    final now = DateTime.now();
    final oneMinuteFromNow = now.add(const Duration(minutes: 1));
    if (timestamp.isAfter(oneMinuteFromNow)) return false;
    
    return true;
  }

  /// Returns a formatted string representation of the value with units
  String get formattedValue {
    return '${value.toStringAsFixed(1)} ${type.unit}';
  }

  /// Returns a formatted timestamp string
  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
           '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is HealthRecord &&
        other.id == id &&
        other.type == type &&
        other.value == value &&
        other.timestamp == timestamp &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        value.hashCode ^
        timestamp.hashCode ^
        notes.hashCode;
  }

  @override
  String toString() {
    return 'HealthRecord(id: $id, type: $type, value: $value, '
           'timestamp: $timestamp, notes: $notes)';
  }
}