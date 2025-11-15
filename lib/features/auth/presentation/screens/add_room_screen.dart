import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'DeviceControlPage.dart';
import 'login_screen.dart';

class AddRoomScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onRoomAdded;
  const AddRoomScreen({super.key, this.onRoomAdded});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _roomNameController = TextEditingController();
  final _espIdController = TextEditingController();

  final databaseRef = FirebaseDatabase.instance.ref("Rooms");

  bool _isSaving = false;

  // 🔹 Save room to Firebase
  Future<void> _saveRoom() async {
    final roomName = _roomNameController.text.trim();
    final espId = _espIdController.text.trim();

    if (roomName.isEmpty || espId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both Room Name and ESP32 ID"),
        ),
      );
      return;
    }



    setState(() => _isSaving = true);

    try {
      print("Saving room...");
      await databaseRef.child(espId).set({
        'name': roomName,
        'espId': espId,
        'status': 'OFF',

      });
      print("Room saved! Navigating...");
      // 🔹 Call Dashboard callback to update room list
      if (widget.onRoomAdded != null) {
        widget.onRoomAdded!({
          'name': roomName,
          'devices': [
            {'name': 'Relay 1', 'status': 'OFF', 'icon': Icons.flash_on},
            {'name': 'Relay 2', 'status': 'OFF', 'icon': Icons.lightbulb_outline},
          ],
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Room '$roomName' added successfully!")),
      );


      // Navigate to DeviceControlPage with the ESP32 chipId
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceControlPage(chipId: espId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding room: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
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
            const SizedBox(height: 16),
            TextField(
              controller: _espIdController,
              decoration: const InputDecoration(
                labelText: 'ESP32 Chip ID',
                hintText: 'Enter your ESP32 unique ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Save Room'),
                onPressed: _isSaving ? null : _saveRoom,

              ),
            ),

          ],
        ),
      ),
    );
  }
}
