import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceControlPage extends StatefulWidget {
  final String chipId;
  const DeviceControlPage({super.key, required this.chipId});

  @override
  State<DeviceControlPage> createState() => _DeviceControlPageState();
}

class _DeviceControlPageState extends State<DeviceControlPage> {
  String deviceStatus = "OFF";

  @override
  void initState() {
    super.initState();
    _listenStatus();
  }

  void _listenStatus() {
    FirebaseDatabase.instance
        .ref("Rooms/${widget.chipId}/status")
        .onValue
        .listen((event) {
      setState(() {
        deviceStatus = event.snapshot.value.toString();
      });
    });
  }

  void turnOn() {
    FirebaseDatabase.instance
        .ref("Rooms/${widget.chipId}/status")
        .set("ON");
  }

  void turnOff() {
    FirebaseDatabase.instance
        .ref("Rooms/${widget.chipId}/status")
        .set("OFF");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Control Device - ${widget.chipId}"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Device Status: $deviceStatus",
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: turnOn,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Turn ON"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: turnOff,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Turn OFF"),
          ),
        ],
      ),
    );
  }
}
