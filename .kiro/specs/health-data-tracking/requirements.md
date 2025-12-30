# Requirements Document

## Introduction

Una aplicación móvil de seguimiento de datos de salud que permite a los usuarios registrar y monitorear sus niveles de glucosa, diámetro de cintura y peso corporal a lo largo del tiempo. Los datos se almacenan localmente en el dispositivo usando SQLite para garantizar privacidad y acceso offline.

## Glossary

- **Health_Tracker**: El sistema principal de la aplicación
- **Health_Record**: Un registro individual que contiene una medición de salud con timestamp
- **Glucose_Level**: Medición de glucosa en sangre (mg/dL)
- **Waist_Diameter**: Medición del diámetro de cintura (cm)
- **Body_Weight**: Medición del peso corporal (kg)
- **SQLite_Database**: Base de datos local para almacenamiento persistente
- **Timestamp**: Fecha y hora exacta cuando se registró la medición

## Requirements

### Requirement 1

**User Story:** Como usuario, quiero registrar mis niveles de glucosa, diámetro de cintura y peso, para poder hacer seguimiento de mi salud a lo largo del tiempo.

#### Acceptance Criteria

1. WHEN a user enters a glucose level value, THE Health_Tracker SHALL validate it is a positive number and store it with current timestamp
2. WHEN a user enters a waist diameter value, THE Health_Tracker SHALL validate it is a positive number and store it with current timestamp  
3. WHEN a user enters a body weight value, THE Health_Tracker SHALL validate it is a positive number and store it with current timestamp
4. WHEN a user submits any health measurement, THE Health_Tracker SHALL persist the data to the SQLite_Database immediately
5. WHEN invalid data is entered, THE Health_Tracker SHALL display clear error messages and prevent storage

### Requirement 2

**User Story:** Como usuario, quiero ver el historial de mis mediciones, para poder analizar tendencias y cambios en mi salud.

#### Acceptance Criteria

1. WHEN a user accesses the history view, THE Health_Tracker SHALL display all stored Health_Records ordered by timestamp (most recent first)
2. WHEN displaying health records, THE Health_Tracker SHALL show the measurement value, type, and formatted timestamp for each entry
3. WHEN the history is empty, THE Health_Tracker SHALL display a helpful message indicating no data has been recorded yet
4. WHEN health records are displayed, THE Health_Tracker SHALL group them by measurement type for better organization

### Requirement 3

**User Story:** Como usuario, quiero que mis datos se guarden localmente en mi dispositivo, para mantener privacidad y acceder a ellos sin conexión a internet.

#### Acceptance Criteria

1. WHEN the app starts for the first time, THE Health_Tracker SHALL create the SQLite_Database with appropriate tables
2. WHEN storing health data, THE Health_Tracker SHALL use SQLite transactions to ensure data integrity
3. WHEN the app is offline, THE Health_Tracker SHALL continue functioning normally for data entry and viewing
4. WHEN data is stored, THE Health_Tracker SHALL ensure it persists between app sessions
5. WHEN database operations fail, THE Health_Tracker SHALL handle errors gracefully and inform the user

### Requirement 4

**User Story:** Como usuario, quiero una interfaz simple e intuitiva, para poder registrar mis datos de salud de manera rápida y eficiente.

#### Acceptance Criteria

1. WHEN the app launches, THE Health_Tracker SHALL display a clean main screen with clear options for data entry
2. WHEN entering measurements, THE Health_Tracker SHALL provide separate input fields for each health metric
3. WHEN a measurement is successfully saved, THE Health_Tracker SHALL provide visual confirmation to the user
4. WHEN navigating between screens, THE Health_Tracker SHALL maintain responsive performance
5. WHEN displaying data, THE Health_Tracker SHALL use appropriate units (mg/dL for glucose, cm for waist, kg for weight)

### Requirement 5

**User Story:** Como desarrollador, quiero una arquitectura limpia y mantenible, para facilitar futuras mejoras y extensiones de la aplicación.

#### Acceptance Criteria

1. WHEN implementing data access, THE Health_Tracker SHALL separate database operations from UI logic
2. WHEN handling different measurement types, THE Health_Tracker SHALL use a consistent data model
3. WHEN managing app state, THE Health_Tracker SHALL follow Flutter best practices for state management
4. WHEN structuring the code, THE Health_Tracker SHALL organize files in logical directories and modules