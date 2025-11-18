//import 'package:firebase_database/firebase_database.dart';
import '../../main.dart';
import '../shared/domain/entities/smart_room.dart';

class FirebaseService {
  final _db = database.ref('rooms');

  Stream<List<SmartRoom>> getRoomsStream() {
    return _db.onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        print(" No room data found in Firebase");
        return [];
      }

      final roomsMap = Map<String, dynamic>.from(data ?? {});
      return roomsMap.entries
          .map((e) => SmartRoom.fromFirebase(e.key, Map<String, dynamic>.from(e.value)))
          .toList();
    });
  }

  Future<void> addRoom(SmartRoom room) async {
    final newRoomRef = _db.push();
    await newRoomRef.set(room.toMap());
    print("Room added: ${room.name}");
  }

  Future<void> toggleRelay(String roomId, String relayKey, bool value) async {
    await _db.child('$roomId/relays/$relayKey').set(value);
    print(" Relay $relayKey toggled to $value for room $roomId");
  }
}

