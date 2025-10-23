import 'package:flutter/material.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});
  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _roomNameController = TextEditingController();
  final List<Map<String, dynamic>> _availableDevices = [
    {'name': 'Light', 'icon': Icons.lightbulb, 'status': 'OFF', 'selected': false},
    {'name': 'Fan', 'icon': Icons.ac_unit, 'status': 'OFF', 'selected': false},
    {'name': 'AC', 'icon': Icons.air, 'status': 'OFF', 'selected': false},
  ];

  void _addRoom() {
    final selectedDevices = _availableDevices
        .where((device) => device['selected'] == true)
        .map((d) => {
      'name': d['name'],
      'icon': d['icon'],
      'status': 'OFF',
    })
        .toList();
    if (_roomNameController.text.isNotEmpty && selectedDevices.isNotEmpty) {
      Navigator.pop(context, {
        'name': _roomNameController.text,
        'devices': selectedDevices,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Room")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _roomNameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: _availableDevices.map((device) {
                  return CheckboxListTile(
                    title: Text(device['name']),
                    secondary: Icon(device['icon']),
                    value: device['selected'],
                    onChanged: (val) {
                      setState(() {
                        device['selected'] = val!;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: _addRoom,
              child: const Text('Save Room'),
            ),
          ],
        ),
      ),
    );
  }
}
