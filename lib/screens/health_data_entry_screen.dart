import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/blocs.dart';
import '../models/models.dart';

/// Screen for entering health data measurements
class HealthDataEntryScreen extends StatefulWidget {
  final HealthMetricType? initialType;
  
  const HealthDataEntryScreen({
    super.key,
    this.initialType,
  });

  @override
  State<HealthDataEntryScreen> createState() => _HealthDataEntryScreenState();
}

class _HealthDataEntryScreenState extends State<HealthDataEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  
  late HealthMetricType _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use the initial type if provided, otherwise default to glucose
    _selectedType = widget.initialType ?? HealthMetricType.glucose;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Datos de Salud'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocListener<HealthTrackingBloc, HealthTrackingState>(
        listener: (context, state) {
          if (state is HealthRecordAdded) {
            setState(() {
              _isLoading = false;
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Clear the form
            _clearForm();
          } else if (state is HealthTrackingValidationError) {
            setState(() {
              _isLoading = false;
            });
            
            // Show validation errors
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errors.join(', ')),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state is HealthTrackingError) {
            setState(() {
              _isLoading = false;
            });
            
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          // Note: Removed HealthTrackingLoading listener to prevent interference from other operations
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card with instructions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nuevo Registro de Salud',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selecciona el tipo de medición e ingresa el valor correspondiente',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Metric type selection
                Text(
                  'Tipo de Medición',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                ...HealthMetricType.values.map((type) => 
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<HealthMetricType>(
                      title: Text(
                        type.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Unidad: ${type.unit} | Rango: ${type.validationRange.min.toInt()}-${type.validationRange.max.toInt()}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      value: type,
                      groupValue: _selectedType,
                      onChanged: (HealthMetricType? value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                            _valueController.clear(); // Clear value when type changes
                          });
                        }
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Value input
                Text(
                  'Valor (${_selectedType.unit})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Ingresa el valor en ${_selectedType.unit}',
                    hintText: _getHintText(_selectedType),
                    suffixText: _selectedType.unit,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(_getIconForType(_selectedType)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un valor';
                    }
                    
                    final doubleValue = double.tryParse(value);
                    if (doubleValue == null) {
                      return 'Por favor ingresa un número válido';
                    }
                    
                    if (doubleValue <= 0) {
                      return 'El valor debe ser mayor que cero';
                    }
                    
                    final range = _selectedType.validationRange;
                    if (doubleValue < range.min || doubleValue > range.max) {
                      return 'El valor debe estar entre ${range.min} y ${range.max} ${_selectedType.unit}';
                    }
                    
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Notes input (optional)
                Text(
                  'Notas (Opcional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Agrega notas adicionales',
                    hintText: 'Ej: Medición en ayunas, después del ejercicio, etc.',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note_add),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Save button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveRecord,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Guardar Registro',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Cancel button
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get hint text based on metric type
  String _getHintText(HealthMetricType type) {
    return switch (type) {
      HealthMetricType.glucose => 'Ej: 120.5',
      HealthMetricType.waistDiameter => 'Ej: 85.0',
      HealthMetricType.bodyWeight => 'Ej: 70.5',
    };
  }

  /// Get icon for metric type
  IconData _getIconForType(HealthMetricType type) {
    return switch (type) {
      HealthMetricType.glucose => Icons.bloodtype,
      HealthMetricType.waistDiameter => Icons.straighten,
      HealthMetricType.bodyWeight => Icons.monitor_weight,
    };
  }

  /// Save the health record
  void _saveRecord() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    final value = double.parse(_valueController.text);
    final notes = _notesController.text.trim().isEmpty 
        ? null 
        : _notesController.text.trim();

    final record = HealthRecord(
      type: _selectedType,
      value: value,
      timestamp: DateTime.now(),
      notes: notes,
    );

    // Add the record using BLoC
    context.read<HealthTrackingBloc>().add(AddHealthRecord(record));
  }

  /// Clear the form after successful save
  void _clearForm() {
    _valueController.clear();
    _notesController.clear();
    _formKey.currentState?.reset();
  }
}