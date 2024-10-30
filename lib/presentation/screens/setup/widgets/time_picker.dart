import 'package:flutter/material.dart';

class TimePickerWidget extends StatelessWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeChanged;

  const TimePickerWidget({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.access_time,color: Colors.white,),
      title: const Text('Sync Time',style: TextStyle(
          color: Colors.white)),
      subtitle: Text(initialTime.format(context),style: const TextStyle(
          color: Colors.white)),
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (picked != null) {
          onTimeChanged(picked);
        }
      },
    );
  }
}