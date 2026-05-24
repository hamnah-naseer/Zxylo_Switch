import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:xyloswitch/features/auth/services/auth_service.dart';
import 'add_room.dart';
import 'show_rooms.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Room> _rooms = [];
  String _homeId = '';
  StreamSubscription? _roomsSubscription;
  String homeName = "Loading..."; // dynamically fetched from Firestore

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHomeDetailsAndLoadRooms();
    });
  }

  Future<void> _fetchHomeDetailsAndLoadRooms() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final hId = authService.homeId;
    if (hId == null || hId.isEmpty) return;

    setState(() {
      _homeId = hId;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('homes').doc(_homeId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        setState(() {
          homeName = docSnapshot.data()!['name'] ?? 'My Home';
        });
      } else {
        setState(() {
          homeName = 'My Home';
        });
      }
    } catch (e) {
      debugPrint("Error fetching home name: $e");
      setState(() {
        homeName = 'My Home';
      });
    }

    _loadRooms();
  }

  @override
  void dispose() {
    _roomsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    final prefs = await SharedPreferences.getInstance();

    final String? roomsJson = prefs.getString('saved_rooms');
    if (roomsJson != null) {
      final List<dynamic> decoded = jsonDecode(roomsJson);
      setState(() {
        _rooms = decoded.map((e) => Room.fromJson(e)).toList();
      });
    }

    if (_homeId.isNotEmpty) {
      _setupRoomsListener();
    }
  }

  void _setupRoomsListener() {
    if (_homeId.isEmpty) return;

    _roomsSubscription?.cancel();

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
      'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
      //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

    _roomsSubscription = db.ref("Homes/$_homeId/RoomConfigs").onValue.listen((
        event,
        ) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map;
        final List<Room> fetchedRooms = [];
        final authService = Provider.of<AuthService>(context, listen: false);
        data.forEach((key, value) {
          try {
            if (value != null) {
              final roomId = key.toString();
              if (authService.isOwner || authService.allowedRooms.contains(roomId)) {
                fetchedRooms.add(Room.fromJson(Map<String, dynamic>.from(value as Map)));
              }
            }
          } catch (e) {
            debugPrint("Error parsing room config for key $key: $e");
          }
        });

        setState(() {
          _rooms = fetchedRooms;
        });

        // Update local cache
        _updateLocalCache();
      } else {
        // If snapshot is null, it means no rooms exist in Firebase for this home
        setState(() {
          _rooms = [];
        });
        _updateLocalCache();
      }
    });
  }

  Future<void> _updateLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_rooms.map((e) => e.toJson()).toList());
    await prefs.setString('saved_rooms', encoded);
  }

  Future<void> _saveRooms() async {
    // 1. Update local cache
    await _updateLocalCache();

    // 2. Sync all rooms to Firebase (or individual ones if preferred)
    if (_homeId.isEmpty) return;
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
      'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
      //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
    );

    for (var room in _rooms) {
      await db.ref("Homes/$_homeId/RoomConfigs/${room.id}").set(room.toJson());
    }
  }

  void _navigateToAddRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoomScreen(
          homeId: _homeId,
          onRoomAdded: (room) {
            setState(() {
              _rooms.add(room);
            });
            _saveRooms();
            // We do not navigate to RoomScreen here, we just return to RoomListScreen
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          homeName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0ABAB5), // Tiffany Blue
                Color(0xFF0095B6), // Bondi Blue
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _rooms.isEmpty
          ? const Center(
        child: Text(
          'No rooms added.\nTap the + button to add a room.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(
                  0xFFE0F2F1,
                ), // Light Teal background
                child: const Icon(
                  Icons.door_front_door,
                  color: Color(0xFF0095B6), // Primary Teal icon
                ),
              ),
              title: Text(
                room.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${room.applianceCount} Devices',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.black54,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoomScreen(
                      room: room,
                      onStateChanged: _saveRooms,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Provider.of<AuthService>(context).isOwner ? Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0ABAB5), // Tiffany Blue
              Color(0xFF0095B6), // Bondi Blue
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0095B6).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _navigateToAddRoom,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add),
          label: const Text(
            "Add Room",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ) : null,
    );
  }
}

class AddRoomScreen extends StatefulWidget {
  final String homeId;
  final Function(Room) onRoomAdded;
  const AddRoomScreen({
    super.key,
    required this.homeId,
    required this.onRoomAdded,
  });

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  int step = 1;

  // STEP 1
  TextEditingController roomController = TextEditingController();
  TextEditingController applianceController = TextEditingController();
  String? _roomNameError;
  String? _applianceCountError;

  // STEP 2
  TextEditingController espNameController = TextEditingController();
  TextEditingController espPasswordController = TextEditingController();
  bool isConnectedToESP = false;
  String? _espNameError;
  String? _espPasswordError;
  List<WifiCredential> additionalWifiList = [];
  String _fetchedHotspotId = '';

  void _showAddAdditionalWifiDialog() {
    final sCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add WiFi Credential"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sCtrl,
              decoration: const InputDecoration(labelText: "SSID"),
            ),
            TextField(
              controller: pCtrl,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                additionalWifiList.add(
                  WifiCredential(
                    ssid: sCtrl.text.trim(),
                    password: pCtrl.text.trim(),
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // STEP 3
  TextEditingController ssidController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isCredentialsSent = false;
  String? _ssidError;
  String? _wifiPasswordError;

  bool isConnecting = false;
  bool _hasNoInternet = false;
  bool _wrongEspCredentials = false;
  bool _wrongWifiCredentials = false;

  // Design Colors
  final Color primaryTeal = const Color(0xFF0095B6);
  final Color darkTeal = const Color(0xFF006680);

  @override
  void dispose() {
    roomController.dispose();
    applianceController.dispose();
    espNameController.dispose();
    espPasswordController.dispose();
    ssidController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Add New Room",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 2,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0ABAB5), // Tiffany Blue
                Color(0xFF0095B6), // Bondi Blue
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepper(),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepIndicator(1, "Details"),
        _buildStepLine(),
        _buildStepIndicator(2, "Connect"),
        _buildStepLine(),
        _buildStepIndicator(3, "WiFi"),
        _buildStepLine(),
        _buildStepIndicator(4, "Finish"),
      ],
    );
  }

  Widget _buildStepIndicator(int stepNumber, String title) {
    bool isActive = step >= stepNumber;
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isActive ? primaryTeal : Colors.grey.shade300,
          child: Text(
            stepNumber.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? primaryTeal : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (step) {
      case 1:
        return stepOneUI();
      case 2:
        return stepTwoUI();
      case 3:
        return stepThreeUI();
      case 4:
        return stepFourUI();
      default:
        return stepOneUI();
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: Icon(icon, color: primaryTeal),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryTeal, width: 2),
        ),
      ),
    );
  }

  Widget stepOneUI() {
    return Card(
      elevation: 4,
      shadowColor: primaryTeal.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Room Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: roomController,
              label: "Room Name",
              icon: Icons.meeting_room,
              errorText: _roomNameError,
              onChanged: (_) => setState(() => _roomNameError = null),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: applianceController,
              label: "Number of Appliances",
              icon: Icons.format_list_numbered,
              keyboardType: TextInputType.number,
              errorText: _applianceCountError,
              onChanged: (_) => setState(() => _applianceCountError = null),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                bool hasError = false;
                setState(() {
                  if (roomController.text.trim().isEmpty) {
                    _roomNameError = "Room name is required";
                    hasError = true;
                  }
                  if (applianceController.text.trim().isEmpty) {
                    _applianceCountError = "Appliance count is required";
                    hasError = true;
                  }
                });

                if (!hasError) {
                  setState(() => step = 2);
                }
              },
              style: _btnStyle(),
              child: const Text("Next", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget stepTwoUI() {
    return Card(
      elevation: 4,
      shadowColor: primaryTeal.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Connect to Xylo Device",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter the Device ID and password to pair your device.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: espNameController,
              label: "Xylo Device ID",
              icon: Icons.memory,
              errorText: _espNameError,
              onChanged: (_) => setState(() => _espNameError = null),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: espPasswordController,
              label: "Device Hotspot Password",
              icon: Icons.lock,
              isPassword: true,
              errorText: _espPasswordError,
              onChanged: (_) => setState(() => _espPasswordError = null),
            ),
            if (_wrongEspCredentials)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "wrong credentials, try again",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isConnecting ? null : connectToESP,
              style: _btnStyle(),
              child: isConnecting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                "Connect to Hotspot",
                style: TextStyle(fontSize: 16),
              ),
            ),
            if (isConnectedToESP) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => setState(() => step = 3),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: primaryTeal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Next",
                  style: TextStyle(fontSize: 16, color: primaryTeal),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget stepThreeUI() {
    return Card(
      elevation: 4,
      shadowColor: primaryTeal.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          key: const ValueKey(3),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Network Configuration",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter your home WiFi details for the Xylo device.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: ssidController,
              label: "Your WiFi SSID",
              icon: Icons.wifi,
              errorText: _ssidError,
              onChanged: (_) => setState(() => _ssidError = null),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: passwordController,
              label: "WiFi Password",
              icon: Icons.lock_outline,
              isPassword: true,
              errorText: _wifiPasswordError,
              onChanged: (_) => setState(() => _wifiPasswordError = null),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Additional WiFi Networks",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF0095B6)),
                  onPressed: _showAddAdditionalWifiDialog,
                ),
              ],
            ),
            if (additionalWifiList.isEmpty)
              const Text(
                "No additional WiFi added.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              )
            else
              ...additionalWifiList.map(
                    (wifi) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.wifi, size: 16),
                  title: Text(wifi.ssid, style: const TextStyle(fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    onPressed: () =>
                        setState(() => additionalWifiList.remove(wifi)),
                  ),
                ),
              ),
            if (_wrongWifiCredentials)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "wrong credentials, try again",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isConnecting ? null : sendWifiCredentials,
              style: _btnStyle(),
              child: isConnecting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                "Send Credentials",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget stepFourUI() {
    return Card(
      elevation: 4,
      shadowColor: primaryTeal.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          key: const ValueKey(4),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Finalize Setup",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Make sure your phone is connected to the internet. (You may need to manually switch back to your home WiFi in your phone settings).",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_hasNoInternet) ...[
              const Icon(
                Icons.sentiment_very_dissatisfied,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 8),
              const Text(
                "You don't have internet connection.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
            ],
            ElevatedButton(
              onPressed: isConnecting ? null : _checkInternetAndFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isConnecting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text("Create Room", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _btnStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryTeal,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> connectToESP() async {
    String espName = espNameController.text.trim();
    String espPass = espPasswordController.text.trim();

    bool hasError = false;
    setState(() {
      if (espName.isEmpty) {
        _espNameError = "Device ID is required";
        hasError = true;
      }
      if (espPass.isEmpty) {
        _espPasswordError = "Password is required";
        hasError = true;
      }
    });

    if (hasError) return;

    setState(() {
      isConnecting = true;
      _wrongEspCredentials = false;
    });

    String hotspotIdToConnect = espName;

    // Check if ESP is valid and fetch hotspot ID
    try {
      final dbRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
        'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
        //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref();
      final snapshot = await dbRef
          .child("Xylo_Switches/$espName")
          .get()
          .timeout(const Duration(seconds: 5));
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (data.containsKey('home_id') && data.containsKey('room')) {
          _showErrorDialog(
            "Device Already in Use",
            "This ESP device is already registered to a home and room. Please use a different device or reset it.",
          );
          setState(() => isConnecting = false);
          return;
        }

        final dbPassword = data['hotspot_password']?.toString();
        if (dbPassword != null && dbPassword != espPass) {
          setState(() {
            _espPasswordError = "Incorrect password";
            isConnecting = false;
          });
          return;
        }

        if (data.containsKey('hotspot_id')) {
          hotspotIdToConnect = data['hotspot_id'].toString();
          _fetchedHotspotId = hotspotIdToConnect;
        }
      } else {
        setState(() {
          _espNameError = "Invalid Device ID";
          isConnecting = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("Could not check Device status: $e");
      _showErrorDialog(
        "Network Error",
        "Could not verify Device ID. Ensure you have internet access before continuing.",
      );
      setState(() => isConnecting = false);
      return;
    }

    try {
      bool connected = await WiFiForIoTPlugin.connect(
        hotspotIdToConnect,
        password: espPass,
        security: NetworkSecurity.WPA,
      ).timeout(const Duration(seconds: 15));

      if (connected) {
        await Future.delayed(const Duration(seconds: 3));
        await WiFiForIoTPlugin.forceWifiUsage(true);

        setState(() {
          isConnectedToESP = true;
        });
        _showSnackBar("Connected successfully to $espName!");

        // Auto-advance after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => step = 3);
        });
      } else {
        setState(() => _wrongEspCredentials = true);
      }
    } catch (e) {
      setState(() => _wrongEspCredentials = true);
    }
    setState(() => isConnecting = false);
  }

  Future<void> sendWifiCredentials() async {
    String ssid = ssidController.text.trim();
    String password = passwordController.text.trim();

    bool hasError = false;
    setState(() {
      if (ssid.isEmpty) {
        _ssidError = "WiFi SSID is required";
        hasError = true;
      }
      if (password.isEmpty) {
        _wifiPasswordError = "Password is required";
        hasError = true;
      }
    });

    if (hasError) return;

    setState(() {
      isConnecting = true;
      _wrongWifiCredentials = false;
    });

    try {
      // 1. Send Primary WiFi
      var response = await http
          .post(
        Uri.parse("http://192.168.4.1/connect"),
        body: {"ssid": ssid, "password": password},
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // 2. Send Additional WiFi networks
        for (var wifi in additionalWifiList) {
          try {
            await http
                .post(
              Uri.parse("http://192.168.4.1/add_wifi"),
              body: {"ssid": wifi.ssid, "pass": wifi.password},
            )
                .timeout(const Duration(seconds: 5));
          } catch (e) {
            debugPrint("Failed to send additional wifi: ${wifi.ssid}");
          }
        }

        setState(() => isCredentialsSent = true);
        _showSnackBar("Success! Xylo device is restarting...");

        // ...

        // Start disconnecting from ESP so user can manually reconnect to internet
        try {
          await WiFiForIoTPlugin.disconnect();
          await WiFiForIoTPlugin.forceWifiUsage(false);
        } catch (e) {
          debugPrint("WiFi handoff error: $e");
        }

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              step = 4;
              _hasNoInternet = false;
            });
          }
        });
      } else {
        setState(() => _wrongWifiCredentials = true);
      }
    } catch (e) {
      setState(() => _wrongWifiCredentials = true);
    }
    setState(() => isConnecting = false);
  }

  Future<void> _checkInternetAndFinish() async {
    setState(() {
      isConnecting = true;
      _hasNoInternet = false;
    });

    bool hasInternet = false;
    try {
      final response = await http
          .get(Uri.parse('https://google.com'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        hasInternet = true;
      }
    } catch (e) {
      hasInternet = false;
    }

    if (!hasInternet) {
      setState(() {
        isConnecting = false;
        _hasNoInternet = true;
      });
      return;
    }

    await _finishSetup();
  }

  Future<void> _finishSetup() async {
    final count = int.tryParse(applianceController.text.trim()) ?? 0;
    if (count > 0) {
      final roomId = espNameController.text.trim();
      final roomName = roomController.text.trim();
      final espPass = espPasswordController.text.trim();
      final actualHotspotId = _fetchedHotspotId;

      // Using widget.homeId instead of hardcoded value
      String homeName = widget.homeId;

      // Write to Firebase Realtime Database
      try {
        final dbRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
          'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
          //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
        ).ref();

        // 1. Create Sensors
        await dbRef.child("Homes/$homeName/Rooms/$roomName/Sensors").set({
          "Current": 0,
          "Energy": 0,
          "Humdity": 0,
          "Person_count": 0,
          "Power": 0,
          "Temperature": 0,
          "Voltage": 0,
        });

        // 2. Create Switches
        Map<String, bool> switchesData = {};
        for (int i = 1; i <= count; i++) {
          switchesData["S$i"] = false;
        }
        await dbRef
            .child("Homes/$homeName/Rooms/$roomName/Switches")
            .set(switchesData);

        // 3. Link ESP Device to Home and Room
        await dbRef.child("Xylo_Switches/$roomId").update({
          "home_id": homeName,
          "room": roomName,
        });

        debugPrint("Successfully wrote config to Firebase");
      } catch (e) {
        debugPrint("Firebase write failed: $e");
        _showSnackBar("Warning: Failed to save to cloud.");
        setState(() => isConnecting = false);
        return;
      }

      final room = Room(
        id: roomId,
        name: roomName,
        homeId: homeName,
        applianceCount: count,
        espHotspotName: actualHotspotId,
        espHotspotPassword: espPass,
        additionalWifi: additionalWifiList,
      );
      widget.onRoomAdded(room);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Success",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text("Room added successfully!"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(
                  context,
                ); // Close AddRoomScreen -> returns to RoomListScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0095B6),
                foregroundColor: Colors.white,
              ),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      _showSnackBar("Invalid appliance count");
      setState(() => isConnecting = false);
    }
  }
}