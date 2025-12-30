# Design Document: Health Data Tracking

## Overview

La aplicación Health Data Tracking es una solución móvil Flutter que permite a los usuarios registrar y monitorear tres métricas clave de salud: niveles de glucosa, diámetro de cintura y peso corporal. La aplicación utiliza SQLite para almacenamiento local, garantizando privacidad de datos y funcionamiento offline completo.

## Architecture

La aplicación sigue una arquitectura en capas limpia:

```
Presentation Layer (UI)
    ↓
Business Logic Layer (BLoC/Provider)
    ↓
Data Access Layer (Repository Pattern)
    ↓
Data Storage Layer (SQLite)
```

### Architectural Patterns:
- **Repository Pattern**: Para abstraer el acceso a datos
- **BLoC Pattern**: Para manejo de estado y lógica de negocio
- **Dependency Injection**: Para desacoplamiento y testabilidad

## Components and Interfaces

### Core Components

#### 1. HealthRecord Model
```dart
class HealthRecord {
  final int? id;
  final HealthMetricType type;
  final double value;
  final DateTime timestamp;
  final String? notes;
}

enum HealthMetricType { glucose, waistDiameter, bodyWeight }
```

#### 2. Database Layer
```dart
abstract class HealthDatabase {
  Future<void> initialize();
  Future<int> insertHealthRecord(HealthRecord record);
  Future<List<HealthRecord>> getAllRecords();
  Future<List<HealthRecord>> getRecordsByType(HealthMetricType type);
  Future<void> deleteRecord(int id);
}

class SQLiteHealthDatabase implements HealthDatabase {
  // SQLite implementation
}
```

#### 3. Repository Layer
```dart
abstract class HealthRepository {
  Future<void> saveHealthRecord(HealthRecord record);
  Future<List<HealthRecord>> getHealthHistory();
  Future<List<HealthRecord>> getHistoryByType(HealthMetricType type);
}

class LocalHealthRepository implements HealthRepository {
  final HealthDatabase _database;
  // Implementation using local database
}
```

#### 4. Business Logic Layer
```dart
class HealthTrackingBloc extends Bloc<HealthTrackingEvent, HealthTrackingState> {
  final HealthRepository _repository;
  // BLoC implementation for state management
}
```

### UI Components

#### 1. Main Screen
- Navigation tabs for different sections
- Quick entry buttons for each metric type
- Recent measurements summary

#### 2. Data Entry Screen
- Input forms for each health metric
- Validation and error handling
- Success confirmation

#### 3. History Screen
- List of all recorded measurements
- Filtering by metric type
- Date-based organization

## Data Models

### Database Schema

#### health_records table
```sql
CREATE TABLE health_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  value REAL NOT NULL,
  timestamp INTEGER NOT NULL,
  notes TEXT,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
```

### Data Validation Rules
- **Glucose**: 0-1000 mg/dL (reasonable medical range)
- **Waist Diameter**: 10-300 cm (reasonable physical range)  
- **Body Weight**: 1-1000 kg (reasonable physical range)
- **Timestamp**: Must be valid DateTime, defaults to current time

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Health metric validation and storage
*For any* valid health measurement (glucose, waist diameter, or body weight), when entered by the user, the system should validate it as a positive number and store it with a current timestamp in the database
**Validates: Requirements 1.1, 1.2, 1.3**

### Property 2: Data persistence with transactions
*For any* health measurement that passes validation, the system should persist it to the SQLite database using transactions to ensure data integrity and immediate availability
**Validates: Requirements 1.4, 3.2**

### Property 3: Invalid input rejection
*For any* invalid health measurement input (negative numbers, non-numeric values, out-of-range values), the system should reject the input, display clear error messages, and prevent storage
**Validates: Requirements 1.5, 3.5**

### Property 4: History ordering consistency
*For any* set of stored health records, when displaying the history, the system should order them by timestamp with the most recent first
**Validates: Requirements 2.1**

### Property 5: Complete record display
*For any* health record being displayed, the system should show the measurement value, type, and formatted timestamp
**Validates: Requirements 2.2**

### Property 6: Type-based grouping
*For any* collection of health records, when displayed, the system should group them by measurement type for organization
**Validates: Requirements 2.4**

### Property 7: Offline functionality preservation
*For any* data entry or viewing operation, the system should function normally when offline, maintaining full functionality without network connectivity
**Validates: Requirements 3.3**

### Property 8: Session persistence
*For any* health data that is successfully stored, it should persist and remain available after app restarts or session changes
**Validates: Requirements 3.4**

### Property 9: Save confirmation feedback
*For any* successfully saved measurement, the system should provide visual confirmation to the user
**Validates: Requirements 4.3**

### Property 10: Appropriate unit display
*For any* health measurement being displayed, the system should show the correct units (mg/dL for glucose, cm for waist diameter, kg for body weight)
**Validates: Requirements 4.5**

## Error Handling

### Error Categories
1. **Validation Errors**: Invalid input data (negative values, non-numeric input)
2. **Database Errors**: SQLite operation failures, transaction rollbacks
3. **System Errors**: Memory issues, file system problems

### Error Handling Strategy
- All errors should be caught and handled gracefully
- User-facing error messages should be clear and actionable
- System should never crash due to user input
- Database transactions ensure data consistency even during failures

## Testing Strategy

### Dual Testing Approach
The application will use both unit tests and property-based tests for comprehensive coverage:

**Unit Tests**: 
- Verify specific examples and edge cases
- Test integration points between components
- Validate error conditions and boundary values
- Focus on concrete scenarios like empty database state, first-time app launch

**Property Tests**:
- Verify universal properties across all inputs using randomized test data
- Test validation logic with generated health measurements
- Verify data persistence and retrieval consistency
- Test ordering and grouping behaviors with various data sets

**Property-Based Testing Configuration**:
- Minimum 100 iterations per property test
- Use Flutter's built-in test framework with property testing extensions
- Each property test references its corresponding design document property
- Tag format: **Feature: health-data-tracking, Property {number}: {property_text}**

### Testing Framework
- **Framework**: Flutter Test with property testing extensions
- **Database Testing**: In-memory SQLite for isolated tests
- **UI Testing**: Widget tests for user interface components
- **Integration Testing**: End-to-end scenarios combining multiple components