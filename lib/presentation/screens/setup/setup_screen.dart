// lib/presentation/screens/setup/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

// import '../../widgets/common/custom_button.dart';
import '../../../core/permission_utils.dart';
import '../file_sync/file_sync_screen.dart';
import '../setup/widgets/folder_list.dart';
import '../setup/widgets/time_picker.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool isDeviceA = false; // false = sender (Phone B), true = receiver (Phone A)
  List<String> selectedFolders = [];
  TimeOfDay syncTime = const TimeOfDay(hour: 1, minute: 0);
  bool autoConnect = true;
  String? deviceName;
  String? pairCode;
  bool isLoading = false;
  bool hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _initializeSetup();
  }

  Future<void> _initializeSetup() async {
    setState(() => isLoading = true);
    hasPermissions = await PermissionUtils.checkPermissions();
    if (hasPermissions) {
      await _loadSavedSettings();
      await _getDeviceName();
    }
    setState(() => isLoading = false);
  }

  Future<void> _requestPermissions() async {
    final granted = await PermissionUtils.requestPermissions();

    setState(() {
      hasPermissions = granted;
    });

    if (!granted && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app needs access to:\n\n'
            '• Storage (to access and sync photos)\n'
            '• Location (to detect WiFi network)\n\n'
            'Please grant the required permissions in settings to continue.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else if (granted) {
      await _loadSavedSettings();
      await _getDeviceName();
    }
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDeviceA = prefs.getBool('isDeviceA') ?? false;
      selectedFolders = prefs.getStringList('selectedFolders') ?? [];
      syncTime = TimeOfDay(
        hour: prefs.getInt('syncHour') ?? 1,
        minute: prefs.getInt('syncMinute') ?? 0,
      );
      autoConnect = prefs.getBool('autoConnect') ?? true;
      pairCode = prefs.getString('pairCode');
    });
  }

  Future<void> _getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name;
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDeviceA', isDeviceA);
    await prefs.setStringList('selectedFolders', selectedFolders);
    await prefs.setInt('syncHour', syncTime.hour);
    await prefs.setInt('syncMinute', syncTime.minute);
    await prefs.setBool('autoConnect', autoConnect);
    if (pairCode != null) {
      await prefs.setString('pairCode', pairCode!);
    }
  }

  Future<void> _selectFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to sync',
      );

      if (selectedDirectory != null &&
          !selectedFolders.contains(selectedDirectory)) {
        setState(() {
          selectedFolders.add(selectedDirectory);
        });
        await _saveSettings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting folder: ${e.toString()}')),
        );
      }
    }
  }

  void _generatePairCode() {
    final code =
        (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    setState(() {
      pairCode = code;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!hasPermissions) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Setup Required'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_open,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Permission Required',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Photo Sync needs access to storage to sync your photos and location permission to detect when devices are on the same WiFi network.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _requestPermissions,
                  child: const Text('Grant Permissions'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Let's setup your app",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
        centerTitle: true,
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Role Selection
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Rounded corners
              ),
              color: Theme.of(context).primaryColor,
              elevation: 4,
              // Subtle shadow for depth
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              // Margin for spacing
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Role',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold, // Bold for emphasis
                            color: Colors
                                .white, // Use a color that matches the theme
                          ),
                    ),
                    const SizedBox(height: 12),
                    // Increased spacing for a modern look
                    SwitchListTile(
                      title: Text(
                        isDeviceA ? 'Receiver (Phone A)' : 'Sender (Phone B)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white, // Match text color to theme
                            ),
                      ),
                      subtitle: Text(
                        isDeviceA
                            ? 'This device will receive and store photos'
                            : 'This device will send photos to Phone A',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Colors.white70, // Subtle color for subtitle
                            ),
                      ),
                      activeColor: Theme.of(context).scaffoldBackgroundColor,
                      // Use secondary color for the switch
                      value: isDeviceA,
                      onChanged: (value) {
                        setState(() {
                          isDeviceA = value;
                        });
                        _saveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Folder Selection (only for sender)
            if (!isDeviceA) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Folders to Sync',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      FolderList(
                        folders: selectedFolders,
                        onRemove: (index) {
                          setState(() {
                            selectedFolders.removeAt(index);
                          });
                          _saveSettings();
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _selectFolder,
                        icon: const Icon(Icons.create_new_folder),
                        label: const Text('Add Folder'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Sync Time Selection
            // Sync Time Selection
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TimePickerWidget(
                      initialTime: syncTime,
                      onTimeChanged: (TimeOfDay newTime) {
                        setState(() {
                          syncTime = newTime;
                        });
                        _saveSettings();
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      activeColor: Theme.of(context).scaffoldBackgroundColor,
                      // Highlight active state
                      title: const Text(
                        'Auto-Connect',
                        style: TextStyle(
                            color: Colors.white), // Ensure title is visible
                      ),
                      subtitle: const Text(
                        'Automatically connect when on same WiFi',
                        style: TextStyle(
                            color: Colors.white70), // Subtle color for contrast
                      ),
                      value: autoConnect,
                      onChanged: (value) {
                        setState(() {
                          autoConnect = value;
                        });
                        _saveSettings();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 4, // Adds depth to the card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
              ),
              color: Theme.of(context).primaryColor, // Dark background for the card
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Pairing',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Ensure title is visible
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Device Name: $deviceName',
                      style: TextStyle(
                          color: Colors.white70), // Subtle color for contrast
                    ),
                    const SizedBox(height: 12),
                    if (isDeviceA) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pair Code: ${pairCode ?? 'Not generated'}',
                              style: TextStyle(
                                  color:
                                      Colors.white), // Ensure code is visible
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Space between Text and Button
                          ElevatedButton(
                            onPressed: _generatePairCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .scaffoldBackgroundColor, // Match primary color
                            ),
                            child: const Text('Generate Code',style: TextStyle(color: Colors.white),),
                          ),
                        ],
                      ),
                    ] else ...[
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Enter Pair Code from Device A',
                          hintText: 'Enter 6-digit code',
                          labelStyle: TextStyle(color: Colors.white70),
                          // Subtle label color
                          hintStyle: TextStyle(color: Colors.white38),
                          // Lighter hint color
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.white70), // Border color
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                    .primaryColor), // Focused border
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        // Text color
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (value) {
                          setState(() {
                            pairCode = value;
                          });
                          _saveSettings();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _validateAndProceed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: const Text('Start Sync Service'),
          ),
        ),
      ),
    );
  }

  Future<void> _validateAndProceed() async {
    if (!isDeviceA && selectedFolders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one folder to sync')),
      );
      return;
    }

    if (pairCode == null || pairCode!.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter/generate a valid pair code')),
      );
      return;
    }
    if (isDeviceA) {
      // For Device A (Server)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FileSyncScreen(isDeviceA: true, pairCode: pairCode),
        ),
      );
    } else {
      // For Device B (Client)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FileSyncScreen(isDeviceA: false, pairCode: pairCode),
        ),
      );
    }
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Choose your device role:'),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text('• Phone A (Receiver): Stores the synced photos\n'
                    '• Phone B (Sender): Sends photos to Phone A'),
              ),
              SizedBox(height: 8),
              Text('2. Select folders to sync (Phone B only)'),
              SizedBox(height: 8),
              Text('3. Set sync time (when photos will be synced daily)'),
              SizedBox(height: 8),
              Text('4. Pair devices using the generated code'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
