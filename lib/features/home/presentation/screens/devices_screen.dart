import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../auth/services/auth_service.dart';


class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  IconData _getIconForDevice(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("light") || lower.contains("bulb")) return Icons.lightbulb_outline;
    if (lower.contains("fan")) return Icons.mode_fan_off_outlined;
    if (lower.contains("ac") || lower.contains("cooler")) return Icons.ac_unit;
    if (lower.contains("tv")) return Icons.tv;
    if (lower.contains("plug") || lower.contains("socket")) return Icons.power;
    return Icons.settings_remote;
  }

  void _toggleDevice(BuildContext context, String espId, String deviceId, bool currentStatus) {
    final homeId = Provider.of<AuthService>(context, listen: false).homeId;
    if (homeId == null) return;
    
    FirebaseFirestore.instance
        .collection('homes')
        .doc(homeId)
        .collection('rooms')
        .doc(espId)
        .update({
      'devices.$deviceId.status': currentStatus ? "OFF" : "ON",
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final homeId = authService.homeId;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FDFF),
      body: Column(
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
                Text(
                  'Your Devices',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.devices, color: Colors.white, size: 28),
              ],
            ),
          ),
          
          Expanded(
            child: homeId == null 
              ? const Center(child: Text("Home ID not found"))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('homes')
                      .doc(homeId)
                      .collection('rooms')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF0095B6)));
                    }

                    final List<Map<String, dynamic>> allDevices = [];

                    for (var doc in snapshot.data!.docs) {
                      final espId = doc.id;
                      final roomData = doc.data() as Map<String, dynamic>;
                      final dynamic devicesValue = roomData['devices'];
                      Map<String, dynamic> devicesData = {};
                      
                      if (devicesValue is Map) {
                        devicesData = Map<String, dynamic>.from(devicesValue);
                      }

                      if (authService.isOwner || authService.allowedRooms.contains(espId)) {
                        devicesData.forEach((deviceId, dValue) {
                          if (dValue is Map) {
                            allDevices.add({
                              'espId': espId,
                              'deviceId': deviceId,
                              'name': dValue['name'] ?? 'Device $deviceId',
                              'room': roomData['name'] ?? 'Unnamed Room',
                              'status': dValue['status'] ?? 'OFF',
                              'icon': _getIconForDevice(dValue['name'] ?? ''),
                            });
                          }
                        });
                      }
                    }

                    if (allDevices.isEmpty) {
                      return const Center(
                        child: Text(
                          "No devices found",
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allDevices.length,
                      itemBuilder: (context, index) {
                        final device = allDevices[index];
                        bool isOn = device['status'] == 'ON';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isOn ? const Color(0xFF0095B6).withValues(alpha: 0.1) : const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  device['icon'],
                                  color: isOn ? const Color(0xFF0095B6) : const Color(0xFF9EABB8),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device['name'],
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1C1E),
                                      ),
                                    ),
                                    Text(
                                      device['room'],
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: const Color(0xFF757575),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isOn,
                                onChanged: (val) => _toggleDevice(context, device['espId'], device['deviceId'], isOn),
                                activeTrackColor: const Color(0xFF3BCFB6).withValues(alpha: 0.5),
                                activeThumbColor: const Color(0xFF3BCFB6),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
