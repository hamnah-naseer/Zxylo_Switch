

import 'package:xyloswitch/core/shared/domain/entities/smart_device.dart';

import 'music_info.dart';

class SmartRoom {


  SmartRoom({

    required this.id,
    required this.name,
    required this.imageUrl,
    required this.temperature,
    required this.airHumidity,
    required this.lights,
    required this.airCondition,
    required this.timer,
    required this.musicInfo,
    required this.espId,
    required this.devices,
    required this.status,
    this.esp32Id,
    this.relays,
  });

  final String id;
  final String name;
  final String imageUrl;
  final double temperature;
  final double airHumidity;
  final SmartDevice lights;
  final SmartDevice airCondition;
  final SmartDevice timer;
  final MusicInfo musicInfo;
  final String? esp32Id;
  final Map<String, bool>? relays;
  final String espId;
  final List<dynamic> devices;
  final String status;

  SmartRoom copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? temperature,
    double? airHumidity,
    SmartDevice? lights,
    SmartDevice? airCondition,
    SmartDevice? timer,
    MusicInfo? musicInfo,
    String? esp32Id,
    Map<String, bool>? relays,
    String? espId,
    List<dynamic>? devices,
    String? status,

  }) =>
      SmartRoom(
        id: id ?? this.id,
        name: name ?? this.name,
        imageUrl: imageUrl ?? this.imageUrl,
        temperature: temperature ?? this.temperature,
        airHumidity: airHumidity ?? this.airHumidity,
        lights: lights ?? this.lights,
        airCondition: airCondition ?? this.airCondition,
        musicInfo: musicInfo ?? this.musicInfo,
        timer: timer ?? this.timer,
        espId: espId ?? this.espId,
        devices: devices ?? this.devices,
        status: status ?? this.status,
        relays: relays ?? this.relays,
      );
  factory SmartRoom.fromFirebase(String id, Map data) {
    return SmartRoom(
      id: id,
      name: data['name'] ?? 'Unnamed Room',
      imageUrl: data['imageUrl'] ?? '',
      temperature: (data['temperature'] ?? 0).toDouble(),
      airHumidity: (data['airHumidity'] ?? 0).toDouble(),
      lights: SmartDevice(isOn: false, value: 0),
      airCondition: SmartDevice(isOn: false, value: 0),
      timer: SmartDevice(isOn: false, value: 0),
      musicInfo: MusicInfo(
        isOn: false,
        currentSong: Song.defaultSong,
      ),
      esp32Id: data['esp32Id'] ?? '',
      relays: Map<String, bool>.from(data['relays'] ?? {}),
      espId: data['espId'] ?? '',
      devices: List.from(data['devices'] ?? []),
      status: data['status'] ?? 'inactive',
    );
  }

  // 🔹 Convert to Firebase map
  Map<String, dynamic> toMap() => {
    'name': name,
    'imageUrl': imageUrl,
    'temperature': temperature,
    'airHumidity': airHumidity,
    'esp32Id': esp32Id ?? '',
    'relays': relays ?? {},
    'espId': espId,
    'devices': devices,
    'status': status,
  };

  static List<SmartRoom> fakeValues = [
    _room,
    _room.copyWith(id: '2', name: 'DINING ROOM', imageUrl: _imagesUrls[2]),
    _room.copyWith(id: '3', name: 'KITCHEN', imageUrl: _imagesUrls[3]),
    _room.copyWith(id: '4', name: 'BEDROOM', imageUrl: _imagesUrls[4]),
    _room.copyWith(id: '5', name: 'BATHROOM', imageUrl: _imagesUrls[1]),
  ];
}

final _room = SmartRoom(
  id: '1',
  name: 'LIVING ROOM',
  imageUrl: _imagesUrls[0],
  temperature: 12,
  airHumidity: 23,
  lights: SmartDevice(isOn: true, value: 20),
  timer: SmartDevice(isOn: false, value: 20),
  airCondition: SmartDevice(isOn: false, value: 10),
  musicInfo: MusicInfo(
    isOn: false,
    currentSong: Song.defaultSong,
  ),
  esp32Id: 'ESP32_001', // example
  relays: {'relay1': true, 'relay2': false},
  espId: 'ESP32_001',
  devices: [],
  status: 'inactive',
);

const _imagesUrls = [
  'assets/images/0.jpeg',
  'assets/images/1.jpeg',
  'assets/images/2.jpeg',
  'assets/images/3.jpeg',
  'assets/images/4.jpeg',
];
