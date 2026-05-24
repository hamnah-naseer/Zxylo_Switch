import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/services/auth_service.dart';

class ManageGuestsScreen extends StatelessWidget {
  const ManageGuestsScreen({super.key});

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
                  'Manage Guests',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.people_outline, color: Colors.white, size: 28),
              ],
            ),
          ),
          
          Expanded(
            child: homeId == null
                ? const Center(child: Text("No home selected"))
                : StreamBuilder<QuerySnapshot>(
                    stream: authService.getHomeMembers(homeId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF0095B6)));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No members found.',
                            style: GoogleFonts.montserrat(fontSize: 16, color: const Color(0xFF757575)),
                          ),
                        );
                      }

                      final members = snapshot.data!.docs;
                      // Filter out the owner and only show guests
                      final guests = members.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['role'] == 'guest';
                      }).toList();

                      if (guests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_off_outlined, color: Color(0xFF9EABB8), size: 80),
                              const SizedBox(height: 16),
                              Text(
                                'No guests in your home.',
                                style: GoogleFonts.montserrat(fontSize: 16, color: const Color(0xFF757575)),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: guests.length,
                        itemBuilder: (context, index) {
                          final guestDoc = guests[index];
                          final userId = guestDoc.id;
                          final guestData = guestDoc.data() as Map<String, dynamic>;
                          final allowedRooms = List<String>.from(guestData['allowedRooms'] ?? []);
                          
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0095B6).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (guestData['name'] as String?)?.substring(0, 1).toUpperCase() ?? 'G',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                              ),
                              title: Text(
                                guestData['name'] ?? 'Guest',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1C1E),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    guestData['email'] ?? 'No email',
                                    style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF757575)),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0095B6).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Access: ${allowedRooms.isEmpty ? 'No rooms' : '${allowedRooms.length} rooms'}",
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10, 
                                        color: const Color(0xFF0095B6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: Color(0xFF0095B6)),
                                    onPressed: () => _showEditRoomsDialog(context, authService, homeId, userId, guestData['name'], allowedRooms),
                                    tooltip: 'Edit Access',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                                    onPressed: () => _showRemoveConfirmDialog(context, authService, homeId, userId, guestData['name']),
                                    tooltip: 'Remove Guest',
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

  void _showEditRoomsDialog(BuildContext context, AuthService authService, String homeId, String userId, String? userName, List<String> currentRooms) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditRoomsDialog(
          authService: authService,
          homeId: homeId,
          userId: userId,
          userName: userName ?? "Guest",
          initialRooms: currentRooms,
        );
      },
    );
  }

  void _showRemoveConfirmDialog(BuildContext context, AuthService authService, String homeId, String userId, String? userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Guest', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to remove ${userName ?? "this guest"} from your home? they will lose all access.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await authService.removeMember(homeId, userId);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class EditRoomsDialog extends StatefulWidget {
  final AuthService authService;
  final String homeId;
  final String userId;
  final String userName;
  final List<String> initialRooms;

  const EditRoomsDialog({
    super.key,
    required this.authService,
    required this.homeId,
    required this.userId,
    required this.userName,
    required this.initialRooms,
  });

  @override
  State<EditRoomsDialog> createState() => _EditRoomsDialogState();
}

class _EditRoomsDialogState extends State<EditRoomsDialog> {
  late List<String> _selectedRooms;

  @override
  void initState() {
    super.initState();
    _selectedRooms = List.from(widget.initialRooms);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Access: ${widget.userName}', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('homes')
                    .doc(widget.homeId)
                    .collection('rooms')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No rooms available.");
                  }

                  final rooms = snapshot.data!.docs;
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final roomDoc = rooms[index];
                      final roomId = roomDoc.id;
                      final roomData = roomDoc.data() as Map<String, dynamic>;
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
            await widget.authService.updateMemberRooms(widget.homeId, widget.userId, _selectedRooms);
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0095B6)),
          child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
