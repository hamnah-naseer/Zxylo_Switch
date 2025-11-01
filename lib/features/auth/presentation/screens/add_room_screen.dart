import 'package:flutter/material.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/shared/domain/entities/music_info.dart';
import '../../../../core/shared/domain/entities/smart_device.dart';
import '../../../../core/shared/domain/entities/smart_room.dart';

class AddRoomScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onRoomAdded;
  const AddRoomScreen({super.key, required this.onRoomAdded});
  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _roomNameController = TextEditingController();
  final _espIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addRoom() async {
    final roomName = _roomNameController.text.trim();
    final espId = _espIdController.text.trim();

    if (roomName.isEmpty || espId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Room Name and ESP32 ID')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {

      final newRoom = SmartRoom(
        id: '', // will be auto-assigned by Firebase
        name: roomName,
        imageUrl: 'assets/images/0.jpeg', // default image
        temperature: 0.0,
        airHumidity: 0.0,
        lights: SmartDevice(isOn: false, value: 0),
        airCondition: SmartDevice(isOn: false, value: 0),
        timer: SmartDevice(isOn: false, value: 0),
        musicInfo: MusicInfo(isOn: false, currentSong: Song.defaultSong),
        esp32Id: espId,
        relays: {'relay1': false, 'relay2': false},
        espId: espId,
        devices: [],
        status: 'inactive',
      );

      await FirebaseService().addRoom(newRoom);
      widget.onRoomAdded({
        'name': roomName,
        'espId': espId,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$roomName added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding room: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
                labelText: 'ESP32 ID',
                hintText: 'Enter your ESP32 unique ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Save Room'),
                onPressed: _isLoading ? null : _addRoom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
