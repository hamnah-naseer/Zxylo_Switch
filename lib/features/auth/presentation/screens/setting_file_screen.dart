import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'about_screen.dart';

class SettingFileScreen extends StatelessWidget {
  const SettingFileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'Settings',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [

                _buildSettingItem(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0095B6).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline, color: Color(0xFF0095B6)),
                    ),
                    title: Text(
                      "About", 
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E)),
                    ),
                    subtitle: Text(
                      "Learn more about Xylo Switch", 
                      style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF757575)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFAFBBC9)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutScreen()),
                      );
                    },
                  ),
                ),
                _buildSettingItem(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0095B6).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.help_outline, color: Color(0xFF0095B6)),
                    ),
                    title: Text(
                      "Help Center", 
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1E)),
                    ),
                    subtitle: Text(
                      "Get support and assistance", 
                      style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF757575)),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFAFBBC9)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text("Contact Help Center", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                            content: Text("Please email us at thexylo.official@gmail.com", style: GoogleFonts.montserrat()),
                            actions: [
                              TextButton(
                                child: Text("Close", style: GoogleFonts.montserrat(color: const Color(0xFF0095B6))),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: child,
    );
  }
}
