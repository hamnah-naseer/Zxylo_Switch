import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../shared/domain/entities/smart_room.dart';
import '../../features/auth/services/auth_service.dart' as auth_service;

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<SmartRoom>> getRoomsStream(auth_service.AuthService authService) {
    final homeId = authService.homeId;
    if (homeId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('rooms')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        debugPrint("No room data found in Firestore for home: $homeId");
        return [];
      }

      final List<SmartRoom> allRooms = snapshot.docs
          .map((doc) => SmartRoom.fromFirebase(doc.id, doc.data()))
          .toList();

      if (authService.isOwner) {
        return allRooms;
      } else {
        return allRooms.where((room) => authService.allowedRooms.contains(room.id)).toList();
      }
    });
  }

  Future<void> addRoom(auth_service.AuthService authService, SmartRoom room) async {
    final homeId = authService.homeId;
    if (homeId == null) return;

    await _firestore
        .collection('homes')
        .doc(homeId)
        .collection('rooms')
        .add(room.toMap());
    debugPrint("Room added to home $homeId: ${room.name}");
  }

  Future<void> toggleRelay(auth_service.AuthService authService, String roomId, String relayKey, bool value) async {
    final homeId = authService.homeId;
    if (homeId == null) return;

    final status = value ? "ON" : "OFF";
    await _firestore
        .collection('homes')
        .doc(homeId)
        .collection('rooms')
        .doc(roomId)
        .update({
      'devices.$relayKey.status': status,
    });
    debugPrint("Relay $relayKey toggled to $status for room $roomId");
  }
}

