import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'add_room_screen.dart';
import 'dart:ui';
import 'energy_consumption_screen.dart';
import 'package:xyloswitch/features/home/presentation/screens/home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String houseName = "My Smart Home";
  bool isEditingHouseName = false;
  final TextEditingController _houseNameController = TextEditingController();
  final _authService = AuthService();
  List<Map<String, dynamic>> rooms = [];


  @override
  void initState() {
    super.initState();
    _houseNameController.text = houseName;
  }

  @override
  void dispose() {
    _houseNameController.dispose();
    super.dispose();
  }

  void _toggleHouseNameEdit() {
    setState(() {
      isEditingHouseName = !isEditingHouseName;
      if (!isEditingHouseName) {
        houseName = _houseNameController.text;
      }
    });
  }

  Future<void> _refreshDashboard() async {
    // TODO: Implement dashboard refresh logic
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
  Widget glassContainer({required Widget child, double opacity = 0.15}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionsSheet(),
        backgroundColor: const Color(0xFF483D8B),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      body: Stack(
        children: [
      // 🔹 Gradient Background
      Container(
      decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3E5C76), Color(0xFF1D2D44)],
        stops: [0.0, 0.3],
      ),
    ),
    ),
    BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
    child: Container(
    color: Colors.white.withValues(alpha: 0.08), // global frost tint
    ),
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
              SliverToBoxAdapter(
                child: _buildRecentActivitySection(),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),

    ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Color(0xFF483D8B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isEditingHouseName
                      ? TextField(
                    controller: _houseNameController,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (value) => _toggleHouseNameEdit(),
                  )
                      : Text(
                    houseName,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _toggleHouseNameEdit,
                  icon: Icon(
                    isEditingHouseName ? Icons.check : Icons.edit,
                    color: const Color(0xFF483D8B),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications,
                    color: Color(0xFF483D8B),
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Logout button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(
                Icons.logout,
                color: Color(0xFF483D8B),
                size: 24,
              ),
            ),
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
        children: [
          Text(
            'Overview',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Row 1
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.show_chart,
                  title: 'Energy Consumption',
                  value: 'Monthly',
                  subtitle: 'View Chart',
                  onTap: () => _navigateToEnergyPage(),
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
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Row 2
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.circle,
                  title: 'Devices Online',
                  value: '8 Devices',
                  subtitle: 'Online',
                  onTap: () => _navigateToDevicesPage(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  icon: Icons.warning,
                  title: 'Alerts',
                  value: '1',
                  subtitle: 'View Alerts',
                  onTap: () => _navigateToAlertsPage(),
                ),
              ),
            ],
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: glassContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
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
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickControlButton(
                  icon: Icons.lightbulb_outline,
                  text: 'Turn All Lights Off',
                  onTap: () => _turnAllLightsOff(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickControlButton(
                  icon: Icons.shield,
                  text: 'Arm Security',
                  onTap: () => _armSecurity(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickControlButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF483D8B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
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
          GestureDetector(
            onTap: _navigateToHomeScreen,
            child: Text(
              'Rooms',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var room in rooms) ...[
                  _buildRoomCard(
                    name: room['name'],
                    devices: List<Map<String, dynamic>>.from(room['devices']),
                  ),
                  const SizedBox(width: 16),
                ],
                _buildAddRoomCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRoomCard({required String name, required List<Map<String, dynamic>> devices}) {
    return GestureDetector(
      onTap: _navigateToHomeScreen,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...devices.map((device){
                bool isOn = device['status'] == 'ON';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              device['icon'],
                              size: 16,
                              color: isOn ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                device['name'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isOn,
                        activeColor: Colors.green,
                        onChanged: (value) {
                          setState(() {
                            device['status'] = value ? 'ON' : 'OFF';
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddRoomCard() {
    return GestureDetector(
      onTap: () => _navigateToAddRoomPage(),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF483D8B), width: 2, style: BorderStyle.solid),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: const Color(0xFF483D8B),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Room',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF483D8B),
              ),
            ),
          ],
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
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSceneButton(
                  icon: Icons.wb_sunny,
                  text: 'Good Morning',
                  onTap: () => _activateGoodMorningScene(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSceneButton(
                  icon: Icons.directions_walk,
                  text: 'Away Mode',
                  onTap: () => _activateAwayModeScene(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSceneButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1D2D44 ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF483D8B).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child:Text(
                text,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF483D8B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Color(0xFF483D8B),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '7:32 PM',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Fan turned ON in Living Room',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

  void _navigateToAlertsPage() {
    // TODO: Navigate to alerts page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Alerts Page')),
    );
  }

  void _navigateToAddRoomPage() async {
    final newRoom = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddRoomScreen(),
      ),
    );

    if (newRoom != null) {
      setState(() {
        rooms.add(newRoom);
      });
    }
  }

  void _navigateToAddDevicePage() {
    // TODO: Navigate to add device page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Add Device Page')),
    );
  }

  void _navigateToSettingsPage() {
    // TODO: Navigate to settings page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Settings Page')),
    );
  }

  void _navigateToHelpPage() {
    // TODO: Navigate to help page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Help Page')),
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _handleLogout(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF483D8B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', // Navigate to splash or login screen
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quick Actions',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    icon: Icons.lightbulb_outline,
                    title: 'Add Device',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToAddDevicePage();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionTile(
                    icon: Icons.room,
                    title: 'Add Room',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToAddRoomPage();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionTile(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToSettingsPage();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionTile(
                    icon: Icons.help,
                    title: 'Help',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      _navigateToHelpPage();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF483D8B),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF483D8B),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Notifications will appear here'),
      ),
    );
  }
}
