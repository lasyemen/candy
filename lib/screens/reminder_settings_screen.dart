import 'package:flutter/material.dart';
import '../core/services/notification_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _bodyController = TextEditingController(
    text: 'Time to drink water 💧',
  );

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _saveReminder() async {
    final title = 'Drink water';
    final body = _bodyController.text.trim();
    final id = 1001; // fixed id for daily water reminder
    await NotificationService.instance.scheduleDailyReminder(
      id: id,
      title: title,
      body: body,
      hour: _time.hour,
      minute: _time.minute,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder scheduled')));
  }

  Future<void> _cancelReminder() async {
    await NotificationService.instance.cancelReminder(1001);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder canceled')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Message'),
            const SizedBox(height: 8),
            TextField(controller: _bodyController),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Time:'),
                const SizedBox(width: 12),
                Text('${_time.format(context)}'),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _pickTime, child: const Text('Pick')),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveReminder,
                  child: const Text('Save'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _cancelReminder,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
