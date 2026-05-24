import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xyloswitch/features/auth/presentation/screens/setting_file_screen.dart';
import 'package:xyloswitch/features/auth/presentation/screens/smart_room.dart';

import 'package:xyloswitch/features/auth/services/auth_service.dart';
import 'package:xyloswitch/features/auth/presentation/screens/energy_consumption_screen.dart';
import 'package:xyloswitch/features/home/presentation/screens/account_screen.dart';
import 'package:xyloswitch/features/home/presentation/screens/devices_screen.dart';
import 'package:xyloswitch/features/home/presentation/screens/join_requests_screen.dart';
import 'package:xyloswitch/features/home/presentation/screens/manage_guests_screen.dart';
import 'package:xyloswitch/features/home/presentation/screens/report_screen.dart';
import 'package:xyloswitch/features/home/presentation/screens/alerts_screen.dart';
import 'package:xyloswitch/features/smart_room/screens/room_detail_screen.dart';
import 'package:xyloswitch/features/home/presentation/widgets/smart_room_page_view.dart';
import 'package:provider/provider.dart';

import '../../../home/presentation/screens/good_morning.dart';
import 'awaymode_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;
  const DashboardScreen({super.key, this.initialIndex = 2});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedIndex;
  List<Map<String, dynamic>> rooms = [];
  StreamSubscription? _roomsSubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // Use a listener to fetch rooms when homeId becomes available or changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleHomeChange();
    });
  }

  void _handleHomeChange() {
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.homeId != null) {
      fetchRooms();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called whenever AuthService notifies listeners
    _handleHomeChange();
  }

  @override
  void dispose() {
    _roomsSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String? _lastFetchedHomeId;

  void fetchRooms() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final homeId = authService.homeId;
    if (homeId == null || homeId == _lastFetchedHomeId) return;

    _lastFetchedHomeId = homeId;
    _roomsSubscription?.cancel();
    
    debugPrint("Fetching rooms for Home: $homeId");
    
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    
    _roomsSubscription = db.ref("Homes/$homeId/RoomConfigs").onValue.listen((event) {
      final List<Map<String, dynamic>> fetchedRooms = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map;
        data.forEach((key, value) {
          try {
            if (value != null) {
              final roomData = Map<String, dynamic>.from(value as Map);
              final roomId = roomData['id']?.toString() ?? key.toString();
              
              // Handle appliances/devices mapping
              final List<Map<String, dynamic>> devices = [];
              if (roomData['appliances'] != null) {
                if (roomData['appliances'] is List) {
                  final appliancesList = roomData['appliances'] as List;
                  for (var app in appliancesList) {
                    if (app != null) {
                      final appData = Map<String, dynamic>.from(app as Map);
                      devices.add({
                        'id': appData['switchId'] ?? '',
                        'name': appData['name'] ?? 'Switch',
                        'status': (appData['isOn'] == true || appData['isOn'] == 'true') ? 'ON' : 'OFF',
                        'icon': _getIconForDevice(appData['name'] ?? ''),
                      });
                    }
                  }
                } else if (roomData['appliances'] is Map) {
                  (roomData['appliances'] as Map).forEach((k, v) {
                    if (v != null) {
                      final appData = Map<String, dynamic>.from(v as Map);
                      devices.add({
                        'id': appData['switchId'] ?? '',
                        'name': appData['name'] ?? 'Switch',
                        'status': (appData['isOn'] == true || appData['isOn'] == 'true') ? 'ON' : 'OFF',
                        'icon': _getIconForDevice(appData['name'] ?? ''),
                      });
                    }
                  });
                }
              }
              devices.sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));

              if (authService.isOwner || authService.allowedRooms.contains(roomId)) {
                fetchedRooms.add({
                  'name': roomData['name'] ?? 'Unnamed Room',
                  'espId': roomId,
                  'devices': devices,
                });
              }
            }
          } catch (e) {
            debugPrint("Error parsing room: $e");
          }
        });
      }
      
      debugPrint("Filtered to ${fetchedRooms.length} allowed rooms for user");
      if (mounted) {
        setState(() {
          rooms = fetchedRooms;
        });
      }
    });
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

  Future<void> _refreshDashboard() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard refreshed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      floatingActionButton: null,

      bottomNavigationBar: Container(
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
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withValues(alpha: 0.6),
          selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Usage'),
            BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Devices'),
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24), 
              label: 'Home',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Report'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          ],
          onTap: _onItemTapped,
        ),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          EnergyConsumptionScreen(),
          DevicesScreen(),
          _buildHomeContent(),
          const ReportScreen(hfSpaceUrl: 'https://saam14635-xylo-ml-backend.hf.space'),
          AccountScreen(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final user = Provider.of<AuthService>(context).currentUser;
    final String displayName = user?.displayName ?? 'User Name';
    final String? photoUrl = user?.photoURL;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Drawer Header with Profile Info
            Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0ABAB5),
                    Color(0xFF0095B6),
                  ],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    backgroundImage: (photoUrl != null && photoUrl.startsWith('http'))
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null)
                        ? Text(
                            displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : "U",
                            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined, color: Color(0xFF0095B6)),
                    title: Text('Home', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 2);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: Color(0xFF0095B6)),
                    title: Text('Settings', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  SettingFileScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  if (Provider.of<AuthService>(context, listen: false).isOwner) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 10, bottom: 5),
                      child: Text(
                        "MANAGEMENT",
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_add_alt_1, color: Color(0xFF0095B6)),
                      title: Text('Join Requests', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const JoinRequestsScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.manage_accounts, color: Color(0xFF0095B6)),
                      title: Text('Manage Guests', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManageGuestsScreen()),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            // Logout at the bottom
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text('Logout', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Stack(
          children: [
            // 🔹 Light Cyan Background
            Container(
              color: const Color(0xFFF6FDFF),
            ),

            SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshDashboard,
                child: CustomScrollView(
                  slivers: [
                    // Header Section
                    SliverToBoxAdapter(
                      child: _buildHeader(),
                    ),

                    // Overview Section
                    SliverToBoxAdapter(
                      child: _buildOverviewSection(),
                    ),

                    // Quick Controls Section
                    SliverToBoxAdapter(
                      child: _buildQuickControlsSection(),
                    ),

                    // Rooms Section
                    SliverToBoxAdapter(
                      child: _buildRoomsSection(),
                    ),

                    // Scenes Section
                    SliverToBoxAdapter(
                      child: _buildScenesSection(),
                    ),

                    // Recent Activity Section
                    //SliverToBoxAdapter(
                      //child: _buildRecentActivitySection(),
                    //),

                    // Bottom padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                  ],
                ),
              ),
            ),

          ]);
  }


  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ),
              const Spacer(),
              Text(
                'Dashboard',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('homes')
                      .doc(Provider.of<AuthService>(context, listen: false).homeId)
                      .collection('alerts')
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AlertsScreen()),
                            );
                          },
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (hasUnread)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B6B),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildOverviewSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Overview',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.show_chart,
                  title: 'Energy Consume',
                  value: 'Monthly',
                  subtitle: 'View Chart',
                  onTap: () => _navigateToEnergyPage(),
                  iconBgColor: const Color(0xFFE8FAF7),
                  iconColor: const Color(0xFF3BCFB6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.flash_on,
                  title: 'Energy Today',
                  value: '2.3 kWh',
                  subtitle: 'View Details',
                  onTap: () => _navigateToEnergyPage(),
                  iconBgColor: const Color(0xFFFFF7E6),
                  iconColor: const Color(0xFFFBB040),
                ),
              ),
            ],
          ),
          ),

          const SizedBox(height: 16),
          // Row 2
          IntrinsicHeight(
          child: Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        int onlineCount = 0;
                        for (var room in rooms) {
                          if (room['devices'] != null) {
                            for (var device in room['devices']) {
                              if (device['status'] == 'ON') onlineCount++;
                            }
                          }
                        }
                        return _buildOverviewCard(
                          icon: Icons.circle,
                          title: 'Devices Online',
                          value: '$onlineCount Devices',
                          subtitle: 'Online',
                          onTap: () => _navigateToDevicesPage(),
                          iconBgColor: const Color(0xFFF0F4F7),
                          iconColor: const Color(0xFF9EABB8),
                        );
                      }
                    ),
                  ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.warning,
                  title: 'Alerts',
                  value: '1',
                  subtitle: 'View Alerts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AlertsScreen()),
                    );
                  },
                  iconBgColor: const Color(0xFFFFEBEB),
                  iconColor: const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconBgColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor ?? const Color(0xFFF0F4F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor ?? const Color(0xFF9EABB8), size: 16),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  color: const Color(0xFF3BCFB6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickControlsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Controls',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildQuickControlButton(
                  icon: Icons.lightbulb_outline,
                  text: 'All Lights',
                  subText: 'Off',
                  onTap: () => _showConfirmationDialog(),
                  iconBgColor: const Color(0xFFE8FAF7),
                  iconColor: const Color(0xFF3BCFB6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickControlButton(
                  icon: Icons.shield_outlined,
                  text: 'Arm',
                  subText: 'Security',
                  onTap: () => _armSecurity(),
                  iconBgColor: const Color(0xFFEBF3FB),
                  iconColor: const Color(0xFF4A90E2),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickControlButton({
    required IconData icon,
    required String text,
    required String subText,
    required VoidCallback onTap,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1C1E),
                    ),
                  ),
                  Text(
                    subText,
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rooms',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _navigateToHomeScreen,
            child: Container(
              height: 80,
              width: double.infinity,
              alignment: Alignment.center,
               decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3BCFB6).withValues(alpha: 0.1),
                  width: 1,
                ),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_outlined, color: Color(0xFF0ABAB5), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Show Rooms",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0ABAB5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Color(0xFF0ABAB5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRoomCard({required String name, required String espId,required List<Map<String, dynamic>> devices}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomDetailScreen(
              espId: espId,
              roomName: name,
            ),
          ),
        ).then((_) => fetchRooms()); // Refresh after coming back
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 4),
              ...devices.map((device){
                bool isOn = device['status'] == 'ON';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        device['icon'],
                        size: 14,
                        color: isOn ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          device['name'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.black54,
                            fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildScenesSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scenes',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildSceneButton(
                  icon: Icons.wb_sunny_outlined,
                  text: 'Good',
                  subText: 'Morning',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const GoodMorningScreen()));
                    _activateGoodMorningScene();
                  },
                  gradient: const [Color(0xFFFBB040), Color(0xFFFF8C00)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSceneButton(
                  icon: Icons.people_outline,
                  text: 'Away',
                  subText: 'Mode',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AwayModeScreen()));
                    _activateAwayModeScene();
                  },
                  gradient: const [Color(0xFF1D2D44), Color(0xFF0F172A)],
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneButton({
    required IconData icon,
    required String text,
    required String subText,
    required VoidCallback onTap,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subText,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // Navigation methods
  void _navigateToEnergyPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EnergyConsumptionScreen(),
      ),
    );
  }

  void _navigateToDevicesPage() {
    // TODO: Navigate to devices page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Devices Page')),
    );
  }




  void _navigateToHomeScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  void _turnAllLightsOff() {
    // TODO: Implement turn all lights off functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All lights turned off')),
    );
  }
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you want to turn off all lights?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);  // close dialog
                _turnAllLightsOff();     // run your function
              },
              child: const Text("YES"),
            ),
          ],
        );
      },
    );
  }


  void _armSecurity() {
    // TODO: Implement arm security functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Security system armed')),
    );
  }

  void _activateGoodMorningScene() {
    // TODO: Implement good morning scene
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Good Morning scene activated')),
    );
  }

  void _activateAwayModeScene() {
    // TODO: Implement away mode scene
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Away Mode scene activated')),
    );
  }

  Future<void> _handleLogout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/', // Navigate to splash or login screen
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}