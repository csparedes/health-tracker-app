import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/blocs.dart';
import 'database/database.dart';
import 'repositories/repositories.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final database = SQLiteHealthDatabase();
  await database.initialize();
  
  // Create repository
  final repository = LocalHealthRepository(database);
  
  runApp(HealthTrackerApp(repository: repository));
}

class HealthTrackerApp extends StatelessWidget {
  final HealthRepository repository;
  
  const HealthTrackerApp({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HealthTrackingBloc(repository),
      child: MaterialApp(
        title: 'Health Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
