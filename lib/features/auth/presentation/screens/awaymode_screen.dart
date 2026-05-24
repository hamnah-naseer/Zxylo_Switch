import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
class AwayModeScreen extends StatefulWidget {
  const AwayModeScreen({super.key});

  @override
  State<AwayModeScreen> createState() => _AwayModeScreenState();
}

class _AwayModeScreenState extends State<AwayModeScreen> {
  bool _isExecuting = false;

  Future<void> _executeAwayMode() async {
    setState(() => _isExecuting = true);
    try {
      final homeId = Provider.of<AuthService>(context, listen: false).homeId;
      if (homeId == null) return;

      final roomsRef = FirebaseFirestore.instance
          .collection('homes')
          .doc(homeId)
          .collection('rooms');

      final snapshot = await roomsRef.get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        final roomData = doc.data();
        final devices = roomData['devices'] as Map<String, dynamic>?;
        if (devices != null) {
          devices.forEach((id, device) {
            // Logic: Turn OFF ALL devices in Away Mode
            batch.update(doc.reference, {'devices.$id.status': 'OFF'});
          });
        }
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Away Mode Activated. All devices turned off.")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isExecuting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildSceneDetailScreen(
      context,
      'Away Mode',
      'Securing your home...',
      Icons.directions_walk,
      [
        'Turning off all lights',
        'Arming security system',
        'Closing all smart locks',
        'Setting AC to Eco mode',
      ],
      _executeAwayMode,
      _isExecuting,
    );
  }

  Widget _buildSceneDetailScreen(BuildContext context, String title, String subtitle, IconData icon, List<String> steps, VoidCallback onAction, bool isLoading) {
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
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
              ],
            ),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0095B6).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 80, color: const Color(0xFF0095B6)),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: steps.map((step) => _buildStep(step)).toList(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0ABAB5), Color(0xFF0095B6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0095B6).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'ACTIVATE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF3BCFB6), size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.montserrat(
              color: const Color(0xFF1A1C1E),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}