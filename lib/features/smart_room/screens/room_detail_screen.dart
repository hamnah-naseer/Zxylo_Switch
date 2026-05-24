import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_service.dart';

class RoomDetailScreen extends StatefulWidget {
  final String espId; // This is the room document ID in Firestore
  final String roomName;

  const RoomDetailScreen({
    super.key,
    required this.espId,
    required this.roomName,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  void _toggleDevice(String deviceId, bool currentStatus) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final homeId = authService.homeId;
    if (homeId == null) return;
    
    final newStatus = currentStatus ? "OFF" : "ON";
    FirebaseFirestore.instance
        .collection('homes')
        .doc(homeId)
        .collection('rooms')
        .doc(widget.espId)
        .update({
      'devices.$deviceId.status': newStatus,
    });
  }

  void _renameDevice(String deviceId, String currentName) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final homeId = authService.homeId;
    if (homeId == null) return;

    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Device"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter device name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                FirebaseFirestore.instance
                    .collection('homes')
                    .doc(homeId)
                    .collection('rooms')
                    .doc(widget.espId)
                    .update({
                  'devices.$deviceId.name': controller.text.trim(),
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeId = Provider.of<AuthService>(context, listen: false).homeId;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6FDFF),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0ABAB5), // Tiffany Blue
                  Color(0xFF0095B6), // Bondi Blue
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.roomName,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.meeting_room, color: Colors.white, size: 28),
              ],
            ),
          ),
          
          Expanded(
            child: homeId == null 
              ? const Center(child: Text("Home ID not found"))
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('homes')
                      .doc(homeId)
                      .collection('rooms')
                      .doc(widget.espId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF0095B6)));
                    }
                    
                    final doc = snapshot.data!;
                    if (!doc.exists || doc.data() == null) {
                      return _buildEmptyState(homeId);
                    }

                    final data = doc.data() as Map<String, dynamic>;
                    final devicesValue = data['devices'];
                    Map<String, dynamic> devicesMap = {};
                    
                    if (devicesValue is Map) {
                      devicesMap = Map<String, dynamic>.from(devicesValue);
                    }

                    if (devicesMap.isEmpty) {
                      return _buildEmptyState(homeId);
                    }

                    final deviceIds = devicesMap.keys.toList()..sort();

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: deviceIds.length,
                      itemBuilder: (context, index) {
                        final id = deviceIds[index];
                        final device = devicesMap[id] as Map<String, dynamic>;
                        final name = device['name'] ?? "Device $id";
                        final status = device['status'] == "ON";

                        return _buildDeviceCard(id, name, status);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String homeId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.devices_other, color: Color(0xFF9EABB8), size: 80),
          const SizedBox(height: 16),
          Text(
            "No devices in this room",
            style: GoogleFonts.montserrat(color: const Color(0xFF757575), fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('homes')
                  .doc(homeId)
                  .collection('rooms')
                  .doc(widget.espId)
                  .set({
                'name': widget.roomName,
                'devices': {
                  '1': {'name': 'Device 1', 'status': 'OFF'},
                  '2': {'name': 'Device 2', 'status': 'OFF'},
                  '3': {'name': 'Device 3', 'status': 'OFF'},
                  '4': {'name': 'Device 4', 'status': 'OFF'},
                }
              }, SetOptions(merge: true));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0095B6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Initialize 4 Devices"),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(String id, String name, bool isOn) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3BCFB6).withValues(alpha: 0.1), width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF6FDFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3BCFB6).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOn ? const Color(0xFF0095B6).withValues(alpha: 0.1) : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForDevice(name),
                    color: isOn ? const Color(0xFF0095B6) : const Color(0xFF9EABB8),
                    size: 20,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF9EABB8), size: 18),
                  onPressed: () => _renameDevice(id, name),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Spacer(),
            Text(
              name,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1C1E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              isOn ? "ON" : "OFF",
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: isOn ? const Color(0xFF3BCFB6) : const Color(0xFF757575),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 24,
              child: Switch(
                value: isOn,
                onChanged: (val) => _toggleDevice(id, isOn),
                activeTrackColor: const Color(0xFF3BCFB6).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFF3BCFB6),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForDevice(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("light") || lower.contains("bulb")) return Icons.lightbulb_outline;
    if (lower.contains("fan")) return Icons.mode_fan_off_outlined;
    if (lower.contains("ac") || lower.contains("cooler")) return Icons.ac_unit;
    if (lower.contains("tv")) return Icons.tv;
    if (lower.contains("plug") || lower.contains("socket")) return Icons.power;
    return Icons.settings_remote;
  }
}

