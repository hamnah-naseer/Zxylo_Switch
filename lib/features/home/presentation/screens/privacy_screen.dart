import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FDFF),
      body: SafeArea(
        child: Column(
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
                Expanded(
                  child: Text(
                    'Privacy & Security',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.security_outlined, color: Colors.white, size: 28),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSection('Data Privacy', 'Your security is our priority. We use advanced encryption to protect your device control data and personal information.'),
                _buildSection('Security Protocols', 'All communication between the app and your smart devices is secured via TLS/SSL. Multi-factor authentication is recommended for all users.'),
                _buildSection('Device Permissions', 'We only request permissions essential for device discovery and control, such as Bluetooth and Local Network access.'),
              ],
            ),
          ),
        ],
      ),
      )
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Color(0xFF3BCFB6), size: 20),
              const SizedBox(width: 8),
              Text(
                title, 
                style: GoogleFonts.montserrat(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: const Color(0xFF1A1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content, 
            style: GoogleFonts.montserrat(
              fontSize: 14, 
              color: const Color(0xFF757575), 
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
