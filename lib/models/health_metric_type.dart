/// Enum representing the different types of health metrics that can be tracked
enum HealthMetricType {
  glucose,
  waistDiameter,
  bodyWeight;

  /// Returns the display name for the metric type in Spanish
  String get displayName {
    switch (this) {
      case HealthMetricType.glucose:
        return 'Glucosa';
      case HealthMetricType.waistDiameter:
        return 'Diámetro de Cintura';
      case HealthMetricType.bodyWeight:
        return 'Peso Corporal';
    }
  }

  /// Returns the unit of measurement for the metric type
  String get unit {
    switch (this) {
      case HealthMetricType.glucose:
        return 'mg/dL';
      case HealthMetricType.waistDiameter:
        return 'cm';
      case HealthMetricType.bodyWeight:
        return 'kg';
    }
  }

  /// Returns the validation range for the metric type
  ({double min, double max}) get validationRange {
    switch (this) {
      case HealthMetricType.glucose:
        return (min: 0.0, max: 1000.0);
      case HealthMetricType.waistDiameter:
        return (min: 10.0, max: 300.0);
      case HealthMetricType.bodyWeight:
        return (min: 1.0, max: 1000.0);
    }
  }

  /// Converts string to HealthMetricType
  static HealthMetricType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'glucose':
        return HealthMetricType.glucose;
      case 'waistdiameter':
        return HealthMetricType.waistDiameter;
      case 'bodyweight':
        return HealthMetricType.bodyWeight;
      default:
        throw ArgumentError('Invalid HealthMetricType: $value');
    }
  }

  /// Converts HealthMetricType to string for database storage
  String toDbString() {
    switch (this) {
      case HealthMetricType.glucose:
        return 'glucose';
      case HealthMetricType.waistDiameter:
        return 'waistDiameter';
      case HealthMetricType.bodyWeight:
        return 'bodyWeight';
    }
  }
}