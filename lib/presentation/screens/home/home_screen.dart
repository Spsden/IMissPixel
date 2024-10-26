// lib/presentation/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../setup/setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isDeviceA = false;
  String? syncTime;
  List<String> selectedFolders = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDeviceA = prefs.getBool('isDeviceA') ?? false;
      selectedFolders = prefs.getStringList('selectedFolders') ?? [];
      final hour = prefs.getInt('syncHour') ?? 1;
      final minute = prefs.getInt('syncMinute') ?? 0;
      syncTime = TimeOfDay(hour: hour, minute: minute).format(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SetupScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body:

      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  isDeviceA ? Icons.download : Icons.upload,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(isDeviceA ? 'Receiver (Phone A)' : 'Sender (Phone B)'),
                subtitle: Text('Sync scheduled at $syncTime'),
              ),
            ),
            const SizedBox(height: 16),
            if (!isDeviceA) ...[
              Text(
                'Syncing Folders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedFolders.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text(selectedFolders[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}