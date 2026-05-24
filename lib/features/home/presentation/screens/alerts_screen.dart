import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../auth/services/auth_service.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeId = Provider.of<AuthService>(context, listen: false).homeId;

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
                  'System Alerts',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
                      .collection('alerts')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF0095B6)));
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none, color: Color(0xFF9EABB8), size: 80),
                            const SizedBox(height: 16),
                            Text(
                              "No alerts at the moment",
                              style: GoogleFonts.montserrat(color: const Color(0xFF757575), fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final alert = doc.data() as Map<String, dynamic>;
                              final type = alert['type'] ?? 'info';
                              final timestamp = alert['timestamp'] as Timestamp?;
                              
                              IconData icon;
                              Color color;
                              
                              switch (type) {
                                case 'security':
                                  icon = Icons.warning_amber_rounded;
                                  color = Colors.redAccent;
                                  break;
                                case 'energy':
                                  icon = Icons.bolt;
                                  color = Colors.orange;
                                  break;
                                case 'access':
                                  icon = Icons.person_outline;
                                  color = Colors.blue;
                                  break;
                                default:
                                  icon = Icons.notifications_none;
                                  color = const Color(0xFF1A1C1E);
                              }

                              String timeStr = "Just now";
                              if (timestamp != null) {
                                timeStr = DateFormat.jm().format(timestamp.toDate());
                                if (DateTime.now().difference(timestamp.toDate()).inDays > 0) {
                                  timeStr = DateFormat.MMMd().format(timestamp.toDate());
                                }
                              }

                              return Dismissible(
                                key: Key(doc.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                ),
                                onDismissed: (direction) {
                                  doc.reference.delete();
                                },
                                child: _buildAlertTile(
                                  alert['title'] ?? 'Alert',
                                  alert['message'] ?? '',
                                  icon,
                                  color,
                                  timeStr,
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextButton(
                            onPressed: () async {
                              final batch = FirebaseFirestore.instance.batch();
                              for (var doc in snapshot.data!.docs) {
                                batch.delete(doc.reference);
                              }
                              await batch.commit();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF0095B6).withValues(alpha: 0.1),
                              foregroundColor: const Color(0xFF0095B6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text("Clear All Alerts", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(String title, String desc, IconData icon, Color color, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title, 
                        style: GoogleFonts.montserrat(color: const Color(0xFF1A1C1E), fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: GoogleFonts.montserrat(color: const Color(0xFF757575), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.montserrat(color: const Color(0xFF757575), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
