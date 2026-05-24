import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'show_rooms.dart';


class RoomScreen extends StatefulWidget {
  final Room room;
  final VoidCallback onStateChanged;


  const RoomScreen({
    super.key,
    required this.room,
    required this.onStateChanged,
  });


  @override
  State<RoomScreen> createState() => _RoomScreenState();
}


class _RoomScreenState extends State<RoomScreen> {
  bool _isRoomOn = true;
  bool _isEditingSwitches = false;
  bool _isEspActive = true; // Start as active until heartbeat confirms


  DatabaseReference? _sensorsRef;
  DatabaseReference? _switchesRef;
  DatabaseReference? _statusRef;
  DatabaseReference? _configRef;
  Timer? _heartbeatTimer;
  Timer? _offlinePollingTimer;
  StreamSubscription? _configSubscription;
  bool _isConnectingHotspot = false;
  Timer? _hourlySaveTimer;


  Map<String, dynamic> _sensorData = {
    "Current": 0,
    "Energy": 0,
    "Humdity": 0,
    "Person_count": 0,
    "Power": 0,
    "Temperature": 0,
    "Voltage": 0,
  };


  Map<String, dynamic> _yesterdayData = {
    "Y_Energy": 0,
    "Y_Power": 0,
    "Y_Voltage": 0,
    "Y_Current": 0,
  };


  @override
  void initState() {
    super.initState();
    if (widget.room.appliances.isNotEmpty) {
      _isRoomOn = widget.room.appliances.every((a) => a.isOn);
    } else {
      _isRoomOn = false;
    }
    _setupFirebaseListeners();
    _startHeartbeat();
    _setupConfigListener();
    _hourlySaveTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _saveCurrentSensorData();
    });
  }


  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _offlinePollingTimer?.cancel();
    _configSubscription?.cancel();
    _hourlySaveTimer?.cancel();
    super.dispose();
  }


  void _saveCurrentSensorData() {
    if (widget.room.homeId.isEmpty) return;
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
      'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
      //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    final ref = db.ref("Homes/${widget.room.homeId}/RoomConfigs/${widget.room.id}");


    Map<String, dynamic> updates = {};
    if ((_sensorData['Energy'] ?? 0) != 0) {
      updates['Y_Energy'] = _sensorData['Energy'];
    }
    if ((_sensorData['Power'] ?? 0) != 0) {
      updates['Y_Power'] = _sensorData['Power'];
    }
    if ((_sensorData['Voltage'] ?? 0) != 0) {
      updates['Y_Voltage'] = _sensorData['Voltage'];
    }
    if ((_sensorData['Current'] ?? 0) != 0) {
      updates['Y_Current'] = _sensorData['Current'];
    }


    if (updates.isNotEmpty) {
      ref.update(updates).catchError((e) => debugPrint("Failed to save hourly sensor data: $e"));
    }
  }


  void _startHeartbeat() {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
      'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
      //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    _statusRef = db.ref("Xylo_Switches/${widget.room.id}/status");


    // Initial reset
    _statusRef!.set(0);


    _heartbeatTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final snapshot = await _statusRef!.get();
        if (snapshot.exists) {
          int status = int.tryParse(snapshot.value.toString()) ?? 0;
          if (status == 1) {
            if (mounted) setState(() => _isEspActive = true);
            await _statusRef!.set(0); // Reset for next cycle
          } else {
            if (mounted) setState(() => _isEspActive = false);
            // Removed redundant set(0) to avoid race conditions with ESP updates
          }
        } else {
          if (mounted) setState(() => _isEspActive = false);
          // If it doesn't exist, we can initialize it to 0
          await _statusRef!.set(0);
        }
      } catch (e) {
        debugPrint("Heartbeat error: $e");
      }
    });
  }


  void _setupFirebaseListeners() {
    if (widget.room.homeId.isEmpty) return;


    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
      'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
      //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
    );
    _sensorsRef = db.ref(
      "Homes/${widget.room.homeId}/Rooms/${widget.room.name}/Sensors",
    );
    _switchesRef = db.ref(
      "Homes/${widget.room.homeId}/Rooms/${widget.room.name}/Switches",
    );


    _sensorsRef!.onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _sensorData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });


    _switchesRef!.onValue.listen((event) {
      if (event.snapshot.value != null && !widget.room.isOffline) {
        Map<String, dynamic> swData = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );
        setState(() {
          for (var app in widget.room.appliances) {
            if (swData.containsKey(app.switchId)) {
              app.isOn = swData[app.switchId] == true;
            }
          }
          if (widget.room.appliances.isNotEmpty) {
            _isRoomOn = widget.room.appliances.every((a) => a.isOn);
          }
        });
      }
    });


    // Start offline polling if already offline
    if (widget.room.isOffline) {
      _startOfflinePolling();
    }
  }


  void _startOfflinePolling() {
    _offlinePollingTimer?.cancel();
    _offlinePollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (widget.room.isOffline) {
        _pollEspData();
      }
    });
  }


  Future<void> _pollEspData() async {
    try {
      final response = await http
          .get(Uri.parse("http://192.168.4.1/data"))
          .timeout(const Duration(seconds: 2));


      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _sensorData = data;
            _isEspActive = true;
            // Update switches
            for (var app in widget.room.appliances) {
              if (data.containsKey(app.switchId)) {
                app.isOn = data[app.switchId] == true;
              }
            }
            if (widget.room.appliances.isNotEmpty) {
              _isRoomOn = widget.room.appliances.every((a) => a.isOn);
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Offline polling error: $e");
      if (mounted) setState(() => _isEspActive = false);
    }
  }


  Future<void> _toggleSwitchOffline(Appliance appliance, bool state) async {
    try {
      final response = await http
          .post(
        Uri.parse("http://192.168.4.1/control"),
        body: {"id": appliance.switchId, "state": state.toString()},
      )
          .timeout(const Duration(seconds: 3));


      if (response.statusCode == 200) {
        setState(() {
          appliance.isOn = state;
          if (widget.room.appliances.isNotEmpty) {
            _isRoomOn = widget.room.appliances.every((a) => a.isOn);
          }
        });
      }
    } catch (e) {
      _showErrorDialog("Failed to control switch offline: $e");
    }
  }


  Future<void> _toggleSwitchOfflineAll(bool state) async {
    for (var app in widget.room.appliances) {
      await _toggleSwitchOffline(app, state);
    }
  }


  void _setupConfigListener() {
    if (widget.room.homeId.isEmpty) return;


    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
      'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
      //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
    );


    _configRef = db.ref(
      "Homes/${widget.room.homeId}/RoomConfigs/${widget.room.id}",
    );


    _configSubscription = _configRef!.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          event.snapshot.value as Map,
        );
        final updatedRoom = Room.fromJson(data);


        setState(() {
          widget.room.name = updatedRoom.name;
          widget.room.espHotspotName = updatedRoom.espHotspotName;
          widget.room.espHotspotPassword = updatedRoom.espHotspotPassword;


          _yesterdayData['Y_Energy'] = data['Y_Energy'] ?? 0;
          _yesterdayData['Y_Power'] = data['Y_Power'] ?? 0;
          _yesterdayData['Y_Voltage'] = data['Y_Voltage'] ?? 0;
          _yesterdayData['Y_Current'] = data['Y_Current'] ?? 0;


          // Update appliance names/icons if they changed
          for (var i = 0; i < widget.room.appliances.length; i++) {
            if (i < updatedRoom.appliances.length) {
              widget.room.appliances[i].name = updatedRoom.appliances[i].name;
              widget.room.appliances[i].iconCode =
                  updatedRoom.appliances[i].iconCode;
            }
          }
        });
      }
    });
  }


  void _showRenameDialog(Appliance appliance) {
    final controller = TextEditingController(text: appliance.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Rename Switch"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Enter new name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  appliance.name = controller.text.trim();
                });
                widget.onStateChanged();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }


  Future<void> _startReconnectionFlow() async {
    // We remove the internal loader dialog as it overlaps with the system bottom sheet
    // and causes interaction issues. We will proceed directly to connection.
    try {
      // 2. Connect to ESP Hotspot with 5s timeout
      final bool connected = await WiFiForIoTPlugin.connect(
        widget.room.espHotspotName,
        password: widget.room.espHotspotPassword,
        security: NetworkSecurity.WPA,
      ).timeout(const Duration(seconds: 5));


      if (connected) {
        await Future.delayed(const Duration(milliseconds: 500));
        await WiFiForIoTPlugin.forceWifiUsage(true);
        _showWifiCredentialsDialog();
      } else {
        _showNoPowerDialog();
      }
    } on TimeoutException catch (_) {
      // If timeout occurs, try to stop the plugin's background process
      try {
        await WiFiForIoTPlugin.disconnect();
      } catch (e) {
        debugPrint("Disconnect failed on timeout: $e");
      }
      _showNoPowerDialog();
    } catch (e) {
      _showErrorDialog("An unexpected error occurred: $e");
    }
  }


  void _showNoPowerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_very_dissatisfied,
              color: Colors.orangeAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              "Seems like Device has No Power",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Could not find Xylo Switch Device's hotspot",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0095B6),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showWifiCredentialsDialog() {
    final ssidCtrl = TextEditingController();
    final passCtrl = TextEditingController();


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isSending = false;
        String? errorMessage;


        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "WiFi Credentials",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Enter your home WiFi details to reconnect the device.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: ssidCtrl,
                      decoration: InputDecoration(
                        labelText: "WiFi SSID",
                        prefixIcon: const Icon(Icons.wifi, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "WiFi Password",
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Additional WiFi List",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF0095B6),
                          ),
                          onPressed: () {
                            _showAddAdditionalWifiDialog(setState);
                          },
                        ),
                      ],
                    ),
                    if (widget.room.additionalWifi.isEmpty)
                      const Text(
                        "No backup networks.",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      )
                    else
                      ...widget.room.additionalWifi.map(
                            (wifi) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            wifi.ssid,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => setState(
                                  () => widget.room.additionalWifi.remove(wifi),
                            ),
                          ),
                        ),
                      ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (isSending) ...[
                      const SizedBox(height: 24),
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0095B6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          "Sending Credentials...",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0095B6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ), // Close SingleChildScrollView
              actions: [
                if (!isSending) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (ssidCtrl.text.trim().isEmpty ||
                          passCtrl.text.trim().isEmpty) {
                        setState(() {
                          errorMessage = "Please fill all fields";
                        });
                        return;
                      }


                      setState(() {
                        isSending = true;
                        errorMessage = null;
                      });


                      try {
                        final response = await http
                            .post(
                          Uri.parse("http://192.168.4.1/connect"),
                          body: {
                            "ssid": ssidCtrl.text.trim(),
                            "password": passCtrl.text.trim(),
                          },
                        )
                            .timeout(const Duration(seconds: 25));


                        if (response.statusCode == 200) {
                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            _showSuccessDialog();


                            // Disconnect from Hotspot to regain internet access
                            try {
                              await WiFiForIoTPlugin.disconnect();
                              await WiFiForIoTPlugin.forceWifiUsage(false);
                            } catch (e) {
                              debugPrint("Disconnect failed: $e");
                            }


                            // Update Firebase mode to online so ESP doesn't revert to offline
                            final db = FirebaseDatabase.instanceFor(
                              app: Firebase.app(),
                              databaseURL:
                              'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
                              //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
                            );


                            Future.microtask(() async {
                              for (int i = 0; i < 5; i++) {
                                await Future.delayed(
                                  const Duration(seconds: 3),
                                );
                                try {
                                  await db
                                      .ref(
                                    "Xylo_Switches/${widget.room.id}/mode",
                                  )
                                      .set("online")
                                      .timeout(const Duration(seconds: 3));
                                  break;
                                } catch (e) {
                                  debugPrint(
                                    "Retry : $e",
                                  );
                                }
                              }
                            });


                            setState(() {
                              widget.room.isOffline = false;
                            });
                            widget.onStateChanged();
                          }
                        } else {
                          setState(() {
                            isSending = false;
                            errorMessage = "Wrong credentials try again";
                          });
                        }
                      } catch (e) {
                        setState(() {
                          isSending = false;
                          errorMessage = "Wrong credentials try again";
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0095B6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Send"),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }


  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 64),
            SizedBox(height: 16),
            Text(
              "Success!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Device reconnected successfully.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );


    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }


  void _showAddAdditionalWifiDialog(Function innerSetState) {
    final sCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Backup WiFi"),
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
              innerSetState(() {
                widget.room.additionalWifi.add(
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


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text("Error", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0095B6),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Soft background
      endDrawer: _SettingsDrawer(
        room: widget.room,
        onStateChanged: widget.onStateChanged,
      ),
      appBar: AppBar(
        title: Text(
          widget.room.name,
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
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchesSection(),
              const SizedBox(height: 24),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildPersonCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildEspStatusCard()),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildGauges(),
              const SizedBox(height: 24),
              _buildGrid(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSwitchesSection() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Appliance Switches",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _isRoomOn,
                onChanged: (val) {
                  if (widget.room.isOffline) {
                    _toggleSwitchOfflineAll(val);
                  } else {
                    if (!_isEspActive) {
                      _showErrorDialog(
                        "Cannot perform action because the device is inactive.",
                      );
                      setState(() {}); // Reset switch visual state
                      return;
                    }
                    setState(() {
                      _isRoomOn = val;
                    });
                    for (var app in widget.room.appliances) {
                      _switchesRef?.child(app.switchId).set(val);
                    }
                  }
                },
                activeColor: Colors.orangeAccent,
              ),
            ),
            IconButton(
              icon: Icon(
                _isEditingSwitches ? Icons.done : Icons.edit,
                color: const Color(0xFF00897B),
              ),
              onPressed: () {
                setState(() {
                  _isEditingSwitches = !_isEditingSwitches;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150, // Increased height slightly to accommodate the circle
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.room.appliances.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final appliance = widget.room.appliances[index];
              return GestureDetector(
                onTap: () {
                  if (_isEditingSwitches)
                    return; // Do not toggle switch when in edit mode
                  if (widget.room.isOffline) {
                    _toggleSwitchOffline(appliance, !appliance.isOn);
                  } else {
                    if (!_isEspActive) {
                      _showErrorDialog(
                        "Cannot perform action because the device is inactive.",
                      );
                      return;
                    }
                    _switchesRef
                        ?.child(appliance.switchId)
                        .set(!appliance.isOn);
                  }
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: appliance.isOn
                        ? const Color(0xE875DFDE)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: appliance.isOn
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          appliance.icon,
                          size: 28,
                          color: appliance.isOn
                              ? Colors.orange
                              : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              appliance.name,
                              style: TextStyle(
                                color: appliance.isOn
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isEditingSwitches) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _showRenameDialog(appliance),
                              child: Icon(
                                Icons.edit,
                                size: 14,
                                color: appliance.isOn
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appliance.isOn ? "ON" : "OFF",
                        style: TextStyle(
                          color: appliance.isOn
                              ? Colors.white70
                              : Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildPersonCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 24, color: Color(0xFF16A34A)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${_sensorData['Person_count'] ?? 0}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  "Persons",
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEspStatusCard() {
    return GestureDetector(
      onTap: () {
        if (!_isEspActive) {
          _startReconnectionFlow();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isEspActive
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isEspActive ? Icons.wifi : Icons.wifi_off,
                size: 24,
                color: _isEspActive
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isEspActive ? "Device Active" : "Device Inactive",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isEspActive ? "Connected" : "Reconnect",
                    style: TextStyle(
                      fontSize: 9,
                      color: _isEspActive
                          ? Colors.grey.shade600
                          : Colors.redAccent,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildGauges() {
    double tempVal = (_sensorData['Temperature'] ?? 0).toDouble();
    double tempPercent = ((tempVal - 16) / (32 - 16)).clamp(0.0, 1.0);


    double humVal = (_sensorData['Humdity'] ?? 0).toDouble();
    double humPercent = (humVal / 100.0).clamp(0.0, 1.0);


    return Row(
      children: [
        Expanded(
          child: _buildGaugeCard(
            "Temperature",
            "$tempVal°C",
            tempPercent,
            "16°C",
            "32°C",
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGaugeCard(
            "Humidity",
            "$humVal%",
            humPercent,
            "0%",
            "100%",
            Colors.blue,
          ),
        ),
      ],
    );
  }


  Widget _buildGaugeCard(
      String label,
      String value,
      double percentage,
      String minVal,
      String maxVal,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              AspectRatio(
                aspectRatio: 2.0,
                child: CustomPaint(
                  painter: GaugePainter(
                    percentage: percentage,
                    activeColor: color,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minVal,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
              Text(
                maxVal,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildGridCard(
          "Energy Consumption",
          "${_sensorData['Energy'] ?? 0}kWh",
          "${_yesterdayData['Y_Energy']}kWh",
          Icons.bolt,
          Colors.orange,
        ),
        _buildGridCard(
          "POWER",
          "${_sensorData['Power'] ?? 0}kW",
          "${_yesterdayData['Y_Power']}kW",
          Icons.power,
          Colors.purple,
        ),
        _buildGridCard(
          "Voltage",
          "${_sensorData['Voltage'] ?? 0}V",
          "${_yesterdayData['Y_Voltage']}V",
          Icons.electrical_services,
          Colors.blue,
        ),
        _buildGridCard(
          "Current",
          "${_sensorData['Current'] ?? 0}A",
          "${_yesterdayData['Y_Current']}A",
          Icons.timeline,
          Colors.red,
        ),
      ],
    );
  }


  Widget _buildGridCard(
      String title,
      String value,
      String increase,
      IconData icon,
      Color iconColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  increase,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  " vs yesterday",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// -------------------------------------------------------------
// SETTINGS DRAWER WIDGET (Authentication + Edits)
// -------------------------------------------------------------
class _SettingsDrawer extends StatefulWidget {
  final Room room;
  final VoidCallback onStateChanged;


  const _SettingsDrawer({required this.room, required this.onStateChanged});


  @override
  State<_SettingsDrawer> createState() => _SettingsDrawerState();
}


class _SettingsDrawerState extends State<_SettingsDrawer> {
  bool _isUnlocked = false;
  bool _isPasswordRevealed = false;


  late TextEditingController espNameCtrl;
  late TextEditingController espPassCtrl;
  bool _isSavingMode = false;


  @override
  void initState() {
    super.initState();
    espNameCtrl = TextEditingController(text: widget.room.espHotspotName);
    espPassCtrl = TextEditingController(text: widget.room.espHotspotPassword);
  }


  Future<void> _updateMode(bool offline) async {
    setState(() => _isSavingMode = true);
    try {
      if (offline) {
        // Switching to Offline
        // 1. Tell ESP via Firebase (if online)
        final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
          'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
          //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
        );
        await db.ref("Xylo_Switches/${widget.room.id}/mode").set("offline");


        // 2. Update local state
        setState(() => widget.room.isOffline = true);


        // 3. App should now try to connect to Hotspot
        await _connectToEspHotspot();
      } else {
        // Switching to Online
        // 1. Tell ESP via HTTP (since we are offline)
        try {
          await http
              .post(
            Uri.parse("http://192.168.4.1/set_mode"),
            body: {"mode": "online"},
          )
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint("Failed to send online mode via HTTP: $e");
        }


        // 2. Update local state
        setState(() => widget.room.isOffline = false);


        // 3. Disconnect from Hotspot
        try {
          await WiFiForIoTPlugin.disconnect();
          await WiFiForIoTPlugin.forceWifiUsage(false);
        } catch (e) {
          debugPrint("Disconnect error: $e");
        }


        // 4. Sync switch states to Firebase
        final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL:
          'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
          //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
        );


        Future.microtask(() async {
          for (int i = 0; i < 5; i++) {
            await Future.delayed(const Duration(seconds: 3));
            try {
              await db
                  .ref("Xylo_Switches/${widget.room.id}/mode")
                  .set("online")
                  .timeout(const Duration(seconds: 3));
              for (var app in widget.room.appliances) {
                await db
                    .ref(
                  "Homes/${widget.room.homeId}/Rooms/${widget.room.name}/Switches/${app.switchId}",
                )
                    .set(app.isOn);
              }
              break;
            } catch (e) {
              debugPrint("Retry : $e");
            }
          }
        });
      }
      widget.onStateChanged();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error switching mode: $e")));
    } finally {
      setState(() => _isSavingMode = false);
    }
  }


  Future<void> _connectToEspHotspot() async {
    try {
      await WiFiForIoTPlugin.connect(
        widget.room.espHotspotName,
        password: widget.room.espHotspotPassword,
        security: NetworkSecurity.WPA,
      );
      await WiFiForIoTPlugin.forceWifiUsage(true);
    } catch (e) {
      debugPrint("Failed to connect to Hotspot: $e");
    }
  }


  Future<void> _deleteRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Delete Room",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this room? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );


    if (confirm != true) return;


    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
        'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
        //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
      );


      // 1. Delete RoomConfigs
      await db
          .ref("Homes/${widget.room.homeId}/RoomConfigs/${widget.room.id}")
          .remove();


      // 2. Delete Sensors and Switches under Rooms
      await db
          .ref("Homes/${widget.room.homeId}/Rooms/${widget.room.name}")
          .remove();


      // 3. Overwrite Xylo_Switches with only hotspot info
      await db.ref("Xylo_Switches/${widget.room.id}").set({
        "hotspot_id": widget.room.espHotspotName,
        "hotspot_password": widget.room.espHotspotPassword,
      });


      if (mounted) {
        // Pop the settings drawer
        Navigator.pop(context);
        // Pop the RoomScreen to return to the home screen
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Failed to delete room: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete room: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  void dispose() {
    espNameCtrl.dispose();
    espPassCtrl.dispose();
    super.dispose();
  }
  void _promptForPassword() {
    final pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text("Enter Passcode"),
            content: TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Passcode",
                errorText: errorMessage,
              ),
              onChanged: (_) {
                if (errorMessage != null) {
                  setStateDialog(() => errorMessage = null);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                  setStateDialog(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  try {
                    final db = FirebaseDatabase.instanceFor(
                      app: Firebase.app(),
                      databaseURL:
                      'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
                      //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
                    );
                    final snapshot = await db
                        .ref("Homes/${widget.room.homeId}/Passcode")
                        .get();
                    final realPasscode = snapshot.value?.toString() ?? "";


                    if (pwdCtrl.text == realPasscode &&
                        realPasscode.isNotEmpty) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() => _isUnlocked = true);
                      }
                    } else {
                      if (context.mounted) {
                        setStateDialog(() => errorMessage = "Incorrect passcode");
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setStateDialog(() => errorMessage = "Failed to verify passcode: $e");
                    }
                  } finally {
                    if (context.mounted) {
                      setStateDialog(() => isLoading = false);
                    }
                  }
                },
                child: isLoading
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text("Unlock"),
              ),
            ],
          ),
        );
      },
    );
  }


  void _promptForPasswordToReveal() {
    final pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text("Enter Passcode"),
            content: TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Passcode",
                errorText: errorMessage,
              ),
              onChanged: (_) {
                if (errorMessage != null) {
                  setStateDialog(() => errorMessage = null);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                  setStateDialog(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  try {
                    final db = FirebaseDatabase.instanceFor(
                      app: Firebase.app(),
                      databaseURL:
                      'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
                      //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
                    );
                    final snapshot = await db
                        .ref("Homes/${widget.room.homeId}/Passcode")
                        .get();
                    final realPasscode = snapshot.value?.toString() ?? "";


                    if (pwdCtrl.text == realPasscode &&
                        realPasscode.isNotEmpty) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() => _isPasswordRevealed = true);
                      }
                    } else {
                      if (context.mounted) {
                        setStateDialog(() => errorMessage = "Incorrect passcode");
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setStateDialog(() => errorMessage = "Failed to verify passcode: $e");
                    }
                  } finally {
                    if (context.mounted) {
                      setStateDialog(() => isLoading = false);
                    }
                  }
                },
                child: isLoading
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text("Reveal"),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              color: const Color(0xFF00897B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.room_preferences,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Room Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (!_isUnlocked)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: _promptForPassword,
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildDrawerTextField(
                    label: "Xylo Switch (Device ID)",
                    initialValue: widget.room.id,
                    readOnly: true,
                  ),
                  const SizedBox(height: 20),
                  _buildDrawerTextField(
                    label: "Hotspot Name",
                    controller: espNameCtrl,
                    readOnly: !_isUnlocked,
                  ),
                  const SizedBox(height: 20),
                  _buildDrawerTextField(
                    label: "Hotspot Password",
                    controller: espPassCtrl,
                    readOnly: !_isUnlocked,
                    obscureText:
                    !_isPasswordRevealed, // Use specific password reveal state
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordRevealed
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        if (_isPasswordRevealed) {
                          setState(() => _isPasswordRevealed = false);
                        } else {
                          if (_isUnlocked) {
                            setState(() => _isPasswordRevealed = true);
                          } else {
                            _promptForPasswordToReveal();
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Offline Mode",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "No Internet ? Control Appliance Offline !",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      if (_isSavingMode)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Switch(
                          value: widget.room.isOffline,
                          onChanged: _updateMode,
                          activeColor: const Color(0xFF00897B),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      "Delete Room",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      "Remove this room and all its devices.",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    onTap: _deleteRoom,
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 20),
                  if (_isUnlocked)
                    ElevatedButton(
                      onPressed: () async {
                        final newName = espNameCtrl.text.trim();
                        final newPass = espPassCtrl.text.trim();


                        setState(() {
                          widget.room.espHotspotName = newName;
                          widget.room.espHotspotPassword = newPass;
                        });


                        try {
                          // If offline, tell ESP immediately
                          if (widget.room.isOffline) {
                            try {
                              await http
                                  .post(
                                Uri.parse("http://192.168.4.1/update_ap"),
                                body: {
                                  "ssid": newName,
                                  "password": newPass,
                                },
                              )
                                  .timeout(const Duration(seconds: 5));
                            } catch (e) {
                              debugPrint("Failed to update AP on Device: $e");
                            }
                          }


                          final db = FirebaseDatabase.instanceFor(
                            app: Firebase.app(),
                            databaseURL:
                            'https://xylo-switch-default-rtdb.asia-southeast1.firebasedatabase.app',
                            //'https://xylo-a910f-default-rtdb.asia-southeast1.firebasedatabase.app',
                          );
                          await db
                              .ref("Xylo_Switches/${widget.room.id}")
                              .update({
                            "hotspot_id": newName,
                            "hotspot_password": newPass,
                          });


                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Hotspot credentials saved successfully!",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint("Failed to update credentials: $e");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to update credentials."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }


                        widget.onStateChanged();
                        if (mounted) {
                          Navigator.pop(context); // close drawer
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(fontSize: 16),
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


  Widget _buildDrawerTextField({
    required String label,
    String? initialValue,
    TextEditingController? controller,
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          controller: controller,
          readOnly: readOnly,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}


// ReconnectEspScreen removed in favor of dialog-based flow.


// -------------------------------------------------------------
// GAUGE PAINTER
// -------------------------------------------------------------
class GaugePainter extends CustomPainter {
  final double percentage;
  final Color activeColor;


  GaugePainter({required this.percentage, required this.activeColor});


  @override
  void paint(Canvas canvas, Size size) {
    Paint trackPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;


    Paint progressPaint = Paint()
      ..color = activeColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;


    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, pi, pi, false, trackPaint);
    canvas.drawArc(rect, pi, pi * percentage, false, progressPaint);


    double radius = size.width / 2;
    double angle = pi + (pi * percentage);
    double x = radius + radius * cos(angle);
    double y = radius + radius * sin(angle);


    Paint dotPaint = Paint()..color = Colors.white;
    Paint dotShadow = Paint()
      ..color = Colors.black12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);


    canvas.drawCircle(Offset(x, y), 8, dotShadow);
    canvas.drawCircle(Offset(x, y), 6, progressPaint);
    canvas.drawCircle(Offset(x, y), 3, dotPaint);
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
