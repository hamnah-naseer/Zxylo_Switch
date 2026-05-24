import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xyloswitch/features/auth/services/auth_service.dart';

class DeviceControlPage extends StatefulWidget {
  final String chipId;
  const DeviceControlPage({super.key, required this.chipId});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  String deviceStatus = "OFF";
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenStatus();
    });
  }

  void _listenStatus() {
    final homeId = Provider.of<AuthService>(context, listen: false).homeId;
    if (homeId == null) return;

    _subscription = FirebaseFirestore.instance
        .collection('homes')
        .doc(homeId)
        .collection('rooms')
        .doc(widget.chipId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          deviceStatus = data['status'] ?? "OFF";
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _updateStatus(String status) {
    final homeId = Provider.of<AuthService>(context, listen: false).homeId;
    if (homeId == null) return;

    FirebaseFirestore.instance
        .collection('homes')
        .doc(homeId)
        .collection('rooms')
        .doc(widget.chipId)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    bool isOn = deviceStatus == "ON";

    return Scaffold(
      backgroundColor: const Color(0xFFF6FDFF),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0ABAB5), Color(0xFF0095B6)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Icon(Icons.settings_remote_outlined, color: Colors.white, size: 28),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Device Control",
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Chip ID: ${widget.chipId}",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: (isOn ? const Color(0xFF0ABAB5) : const Color(0xFF0095B6)).withValues(alpha: 0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                        size: 100,
                        color: isOn ? const Color(0xFF0ABAB5) : const Color(0xFFAFBBC9),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        deviceStatus,
                        style: GoogleFonts.montserrat(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: isOn ? const Color(0xFF0ABAB5) : const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            "ON",
                            Colors.greenAccent.shade700,
                            isOn,
                            () => _updateStatus("ON"),
                          ),
                          const SizedBox(width: 20),
                          _buildControlButton(
                            "OFF",
                            Colors.redAccent.shade700,
                            !isOn,
                            () => _updateStatus("OFF"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String label, Color color, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? color : const Color(0xFFAFBBC9), width: 2),
            boxShadow: isActive ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFFAFBBC9),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
