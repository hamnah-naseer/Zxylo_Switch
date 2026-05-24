import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:xyloswitch/features/auth/services/auth_service.dart';
import 'package:xyloswitch/features/auth/presentation/screens/dashboard_screen.dart';
import 'package:xyloswitch/features/auth/presentation/screens/setting_file_screen.dart';
import 'alerts_screen.dart';
import 'privacy_screen.dart';
import 'help_screen.dart';
import 'join_requests_screen.dart';
import 'package:xyloswitch/features/auth/presentation/screens/sign_in_screen.dart';
import 'report_screen.dart';
import 'package:local_auth/local_auth.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? _user;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  late String _displayName;

  bool _isCodeVisible = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _refreshUser();
  }

  Future<void> _authenticateAndRevealCode() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to reveal the Home Code',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (didAuthenticate) {
        setState(() {
          _isCodeVisible = true;
        });
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _isCodeVisible = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint("Error authenticating: $e");
    }
  }

  void _refreshUser() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
      _displayName = _user?.displayName ?? 'User Name';
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      try {
        await _user?.updatePhotoURL(pickedFile.path);
        await _user?.reload();
        _refreshUser();
      } catch (e) {
        debugPrint("Error updating photo URL: $e");
      }
    }
  }

  void _editName() {
    final TextEditingController nameController = TextEditingController(text: _displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Name', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter your name"),
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await _user?.updateDisplayName(nameController.text);
                  await _user?.reload();
                  _refreshUser();
                } catch (e) {
                  debugPrint("Error updating name: $e");
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0095B6)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to log out from ${_user?.email ?? "your account"}?', style: GoogleFonts.montserrat()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('No', style: GoogleFonts.montserrat(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text('Yes', style: GoogleFonts.montserrat(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = _user?.photoURL;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0ABAB5), // Tiffany Blue
            Color(0xFF0095B6), // Bondi Blue
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white24,
                  backgroundImage: _imageFile != null 
                      ? FileImage(_imageFile!) 
                      : (photoUrl != null && photoUrl.startsWith('http') 
                          ? NetworkImage(photoUrl) 
                          : (photoUrl != null 
                              ? FileImage(File(photoUrl)) as ImageProvider 
                              : null)),
                  child: (_imageFile == null && photoUrl == null)
                      ? Text(
                          _displayName.isNotEmpty ? _displayName.substring(0, 1).toUpperCase() : "U",
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0095B6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 32), // Spacer for centering
                Text(
                  _displayName,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: _editName,
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ],
            ),
            Text(
              _user?.email ?? 'user@example.com',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  children: [
                    if (Provider.of<AuthService>(context).isOwner)
                      _buildHomeCodeSection(context),
                    if (Provider.of<AuthService>(context).isOwner)
                      const Divider(),
                    _buildOption(
                      context,
                      icon: Icons.settings,
                      title: 'App Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SettingFileScreen()),
                        );
                      },
                    ),
                    if (Provider.of<AuthService>(context).isOwner)
                      _buildOption(
                        context,
                        icon: Icons.group_add,
                        title: 'Join Requests',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JoinRequestsScreen()),
                          );
                        },
                      ),
                    _buildOption(
                      context,
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AlertsScreen()),
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      icon: Icons.security,
                      title: 'Privacy & Security',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HelpScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    _buildOption(
                      context,
                      icon: Icons.login,
                      title: 'Login ',
                      color: const Color(0xFF0095B6),
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreens()),
                          (route) => false,
                        );
                      },
                    ),
                    _buildOption(
                      context,
                      icon: Icons.logout,
                      title: 'Logout',
                      color: Colors.redAccent,
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color color = Colors.black87}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildHomeCodeSection(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final code = authService.homeCode ?? "N/A";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0095B6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0095B6).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key, color: Color(0xFF0095B6), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home Share Code',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isCodeVisible ? code : "••••••••",
                  style: GoogleFonts.montserrat(
                    fontSize: _isCodeVisible ? 14 : 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: _isCodeVisible ? 2.0 : 4.0,
                    color: const Color(0xFF0095B6),
                  ),
                ),
              ],
            ),
          ),
          if (!_isCodeVisible)
            TextButton(
              onPressed: _authenticateAndRevealCode,
              child: Text(
                "Reveal",
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0095B6),
                ),
              ),
            ),
          if (_isCodeVisible)
            IconButton(
              icon: const Icon(Icons.copy, color: Color(0xFF0095B6)),
              onPressed: () {
                if (code != "N/A") {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard!')),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
