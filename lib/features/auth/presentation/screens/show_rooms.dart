import 'package:flutter/material.dart';

class Appliance {
  String switchId; // e.g. "S1", "S2"
  String name;
  bool isOn;
  int iconCode;

  Appliance({
    required this.switchId,
    required this.name,
    this.isOn = false,
    required this.iconCode,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() => {
    'switchId': switchId,
    'name': name,
    'isOn': isOn,
    'iconCode': iconCode,
  };

  factory Appliance.fromJson(Map<String, dynamic> json) => Appliance(
    switchId: json['switchId']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Switch',
    isOn: json['isOn'] == true || json['isOn'] == 'true',
    iconCode: int.tryParse(json['iconCode']?.toString() ?? '') ?? 0xe23c, // Icons.electrical_services.codePoint fallback
  );
}

class WifiCredential {
  String ssid;
  String password;

  WifiCredential({required this.ssid, required this.password});

  Map<String, dynamic> toJson() => {
    'ssid': ssid,
    'password': password,
  };

  factory WifiCredential.fromJson(Map<String, dynamic> json) => WifiCredential(
    ssid: json['ssid'] ?? '',
    password: json['password'] ?? '',
  );
}

class Room {
  final String id;
  String name;
  String homeId;
  final int applianceCount;
  String espHotspotName;
  String espHotspotPassword;
  bool isOffline;
  List<WifiCredential> additionalWifi;
  List<Appliance> appliances;

  Room({
    required this.id,
    required this.name,
    required this.homeId,
    required this.applianceCount,
    this.espHotspotName = '',
    this.espHotspotPassword = '',
    this.isOffline = false,
    List<WifiCredential>? additionalWifi,
    List<Appliance>? appliances,
  })  : additionalWifi = additionalWifi ?? [],
        appliances = appliances ?? _generateDefaultAppliances(applianceCount);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'homeId': homeId,
    'applianceCount': applianceCount,
    'espHotspotName': espHotspotName,
    'espHotspotPassword': espHotspotPassword,
    'isOffline': isOffline,
    'additionalWifi': additionalWifi.map((e) => e.toJson()).toList(),
    'appliances': appliances.map((e) => e.toJson()).toList(),
  };

  factory Room.fromJson(Map<String, dynamic> json) {
    int count = int.tryParse(json['applianceCount']?.toString() ?? '') ?? 0;

    List<Appliance> parsedAppliances = [];
    if (json['appliances'] != null) {
      if (json['appliances'] is List) {
        parsedAppliances = (json['appliances'] as List)
            .where((e) => e != null)
            .map((e) => Appliance.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else if (json['appliances'] is Map) {
        (json['appliances'] as Map).forEach((key, value) {
          if (value != null) {
            parsedAppliances.add(Appliance.fromJson(Map<String, dynamic>.from(value as Map)));
          }
        });
      }
    }

    if (parsedAppliances.isEmpty && count > 0) {
      parsedAppliances = _generateDefaultAppliances(count);
    }

    return Room(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Room',
      homeId: json['homeId']?.toString() ?? '',
      applianceCount: count,
      espHotspotName: json['espHotspotName']?.toString() ?? '',
      espHotspotPassword: json['espHotspotPassword']?.toString() ?? '',
      isOffline: json['isOffline'] == true || json['isOffline'] == 'true',
      additionalWifi: (json['additionalWifi'] as List?)
          ?.where((e) => e != null)
          .map((e) => WifiCredential.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ??
          [],
      appliances: parsedAppliances,
    );
  }

  static List<Appliance> _generateDefaultAppliances(int count) {
    return List.generate(count, (index) {
      int iconCode;
      switch (index % 4) {
        case 0:
          iconCode = Icons.lightbulb.codePoint;
          break;
        case 1:
          iconCode = Icons.electrical_services_rounded.codePoint;
          break;
        case 2:
          iconCode = Icons.mode_fan_off.codePoint;
          break;
        case 3:
          iconCode = Icons.lightbulb.codePoint;
          break;
        default:
          iconCode = Icons.electrical_services.codePoint;
      }
      return Appliance(
        switchId: 'S${index + 1}',
        name: 'S${index + 1}',
        isOn: false,
        iconCode: iconCode,
      );
    });
  }
}