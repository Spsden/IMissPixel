import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:i_miss_pixel/presentation/bloc/connection/connection_bloc.dart';
import 'package:i_miss_pixel/presentation/screens/home/home_screen.dart';
import 'package:i_miss_pixel/presentation/screens/setup/setup_screen.dart';
import 'package:i_miss_pixel/presentation/screens/splash_screen.dart';
import 'package:i_miss_pixel/services/network/socket/socket_service_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp( IMissPixel());
}

class IMissPixel extends StatelessWidget {
   IMissPixel({super.key});
  final repository = WebSocketRepository();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ConnectionBloc(repository)),
      ],
      child: MaterialApp(
        title: 'Photo Sync',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AppStarter(),
      ),
    );
  }
}

class AppStarter extends StatefulWidget {
  const AppStarter({super.key});

  @override
  State<AppStarter> createState() => _AppStarterState();
}

class _AppStarterState extends State<AppStarter> {
  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isSetupComplete = prefs.getBool('isSetupComplete') ?? false;

    if (!mounted) return;


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isSetupComplete
            ? const HomeScreen()
            : const SetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

