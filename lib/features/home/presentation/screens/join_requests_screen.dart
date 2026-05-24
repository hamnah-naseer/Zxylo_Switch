import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../auth/services/auth_service.dart';

class JoinRequestsScreen extends StatelessWidget {
  const JoinRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
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
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Join Requests',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.person_add_outlined, color: Colors.white, size: 28),
              ],
            ),
          ),
          
          Expanded(
            child: homeId == null
                ? const Center(child: Text("No home selected"))
                : StreamBuilder<QuerySnapshot>(
                    stream: authService.getJoinRequests(homeId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF0095B6)));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.hourglass_empty, color: Color(0xFF9EABB8), size: 80),
                              const SizedBox(height: 16),
                              Text(
                                'No pending requests.',
                                style: GoogleFonts.montserrat(fontSize: 16, color: const Color(0xFF757575)),
                              ),
                            ],
                          ),
                        );
                      }

                      final requests = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final reqDoc = requests[index];
                          final userId = reqDoc.id;
                          final reqData = reqDoc.data() as Map<String, dynamic>;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
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
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0ABAB5), Color(0xFF0095B6)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    (reqData['name'] as String?)?.substring(0, 1).toUpperCase() ?? 'U',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                              ),
                              title: Text(
                                reqData['name'] ?? 'Unknown User',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1C1E),
                                ),
                              ),
                              subtitle: Text(
                                reqData['email'] ?? 'No email',
                                style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF757575)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                    onPressed: () => _showApprovalDialog(context, authService, homeId, userId, reqData['name'], reqData['email']),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                                    onPressed: () => authService.denyJoinRequest(homeId, userId),
                                  ),
                                ],
                              ),
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

  void _showApprovalDialog(BuildContext context, AuthService authService, String homeId, String userId, String? userName, String? userEmail) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return RoomSelectionDialog(
          authService: authService,
          homeId: homeId,
          userId: userId,
          userName: userName ?? "User",
          userEmail: userEmail ?? "",
        );
      },
    );
  }
}

class RoomSelectionDialog extends StatefulWidget {
  final AuthService authService;
  final String homeId;
  final String userId;
  final String userName;
  final String userEmail;

  const RoomSelectionDialog({
    super.key,
    required this.authService,
    required this.homeId,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<RoomSelectionDialog> createState() => _RoomSelectionDialogState();
}

class _RoomSelectionDialogState extends State<RoomSelectionDialog> {
  final List<String> _selectedRooms = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Approve ${widget.userName}', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select rooms this user can access:',
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instanceFor(
                        app: Firebase.app(),
                        databaseURL: 'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app')
                    .ref('Homes/${widget.homeId}/RoomConfigs')
                    .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Text("No rooms available.");
                  }

                  final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  final rooms = data.entries.toList();
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final roomEntry = rooms[index];
                      final roomId = roomEntry.key.toString();
                      final roomData = Map<String, dynamic>.from(roomEntry.value as Map);
                      final roomName = roomData['name'] ?? 'Unnamed Room';
                      
                      return CheckboxListTile(
                        title: Text(roomName, style: GoogleFonts.montserrat()),
                        value: _selectedRooms.contains(roomId),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedRooms.add(roomId);
                            } else {
                              _selectedRooms.remove(roomId);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await widget.authService.approveJoinRequest(widget.homeId, widget.userId, _selectedRooms, widget.userName, widget.userEmail);
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0095B6)),
          child: const Text('Approve', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
