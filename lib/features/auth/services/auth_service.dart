import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';


import 'package:uuid/uuid.dart';


class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _serverClientId = '430057925240-2ns5ko54lbtmgmohe5e9vmkn7mecidel.apps.googleusercontent.com';


  AuthService() {
    // google_sign_in 7.x uses GoogleSignIn.instance
  }

  bool _isAuthenticated = false;
  String? _userEmail;
  String? _homeId;
  String? _homeName;
  String? _homeCode;
  String? _ownerId;
  bool _isPendingApproval = false;
  String? _pendingHomeId;
  List<String> _allowedRooms = [];
  StreamSubscription? _userSubscription;
  StreamSubscription? _memberSubscription;

  User? get currentUser => _auth.currentUser;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get homeId => _homeId;
  String? get homeName => _homeName;
  String? get homeCode => _homeCode;
  String? get ownerId => _ownerId;
  bool get isOwner => _auth.currentUser?.uid == _ownerId;
  bool get isPendingApproval => _isPendingApproval;
  String? get pendingHomeId => _pendingHomeId;
  List<String> get allowedRooms => _allowedRooms;
  bool get isGuest => isAuthenticated && homeId != null && !isOwner;

  // 🔹 LOGIN
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      _isAuthenticated = true;
      _userEmail = email;
      await fetchUserHome();
      startUserListener(); // Start listening for changes
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint("Login error: ${e.code}");
      switch (e.code) {
        case 'user-not-found':
          return "No user found with this email. Please sign up first.";
        case 'wrong-password':
          return "Incorrect password. Please try again.";
        case 'invalid-email':
          return "The email address is not valid.";
        case 'user-disabled':
          return "This user account has been disabled.";
        case 'too-many-requests':
          return "Too many attempts. Please try again later.";
        default:
          return e.message ?? "Login failed. Please check your credentials.";
      }
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

  // 🔹 LOGOUT
  Future<void> logout() async {
    _userSubscription?.cancel();
    _userSubscription = null;
    _memberSubscription?.cancel();
    _memberSubscription = null;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint("Google Sign Out Error: $e");
    }
    await _auth.signOut();
    _isAuthenticated = false;
    _userEmail = null;
    _homeId = null;
    _homeName = null;
    _homeCode = null;
    _ownerId = null;
    _isPendingApproval = false;
    _pendingHomeId = null;
    _allowedRooms = [];
    notifyListeners();
  }

  // 🔹 SIGNUP
  Future<bool> signup({
    required String fullName,
    required String email,
    required String contact,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      // Update display name
      await credential.user?.updateDisplayName(fullName);
      
      // Initialize user in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'contact': contact,
        'homeId': null,
      });

      _isAuthenticated = true;
      _userEmail = email;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint("Signup error: ${e.message}");
      return false;
    }
  }

  // 🔹 FETCH USER HOME (Entirely via Realtime Database)
  // 🔹 FETCH USER HOME (Migrated to Firestore)
  Future<void> fetchUserHome() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _homeId = userData['homeId'] as String?;
          _pendingHomeId = userData['pendingHomeId'] as String?;
          _isPendingApproval = _pendingHomeId != null;
          
          if (_homeId != null) {
            await _fetchHomeDetails();
          }
        }
      } catch (e) {
        debugPrint("Error fetching user home: $e");
        _homeId = null;
        _homeName = null;
        _homeCode = null;
        _ownerId = null;
      }
    }
  }

  // Helper for detail fetching (Firestore)
  Future<void> _fetchHomeDetails() async {
    final user = _auth.currentUser;
    if (_homeId == null || user == null) return;
    try {
      final homeDoc = await _firestore.collection('homes').doc(_homeId!).get();
      if (homeDoc.exists) {
        final homeData = homeDoc.data() as Map<String, dynamic>;
        _homeName = homeData['name'];
        _homeCode = homeData['code'];
        _ownerId = homeData['ownerId'];

        if (user.uid != _ownerId) {
          final memberDoc = await _firestore
              .collection('homes')
              .doc(_homeId!)
              .collection('members')
              .doc(user.uid)
              .get();
              
          if (memberDoc.exists) {
            final memberData = memberDoc.data() as Map<String, dynamic>;
            if (memberData['allowedRooms'] != null) {
              _allowedRooms = List<String>.from(memberData['allowedRooms']);
            } else {
              _allowedRooms = [];
            }
          }
          startMemberListener(); // 🔹 Start real-time permission listener for guests
        } else {
          _allowedRooms = [];
        }
      }
    } catch (e) {
      debugPrint("Error fetching home details: $e");
    }
  }

  // 🔹 START USER LISTENER (Firestore)
  void startUserListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    _userSubscription?.cancel();
    _userSubscription = _firestore.collection('users').doc(user.uid).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        final newHomeId = userData['homeId'] as String?;
        final newPendingHomeId = userData['pendingHomeId'] as String?;
        
        bool changed = false;
        
        if (newHomeId != _homeId) {
          _homeId = newHomeId;
          changed = true;
          
          if (_homeId != null) {
            notifyListeners(); 
            await _fetchHomeDetails();
          } else {
            _homeName = null;
            _homeCode = null;
            _ownerId = null;
            _allowedRooms = [];
          }
        }
        
        if (newPendingHomeId != _pendingHomeId) {
          _pendingHomeId = newPendingHomeId;
          _isPendingApproval = _pendingHomeId != null;
          changed = true;
        }

        if (changed) {
          notifyListeners();
        }
      }
    });
  }

  // 🔹 START MEMBER LISTENER (Firestore)
  void startMemberListener() {
    final user = _auth.currentUser;
    if (user == null || _homeId == null || _ownerId == user.uid) return;

    _memberSubscription?.cancel();
    _memberSubscription = _firestore
        .collection('homes')
        .doc(_homeId!)
        .collection('members')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final memberData = snapshot.data() as Map<String, dynamic>;
        if (memberData['allowedRooms'] != null) {
          _allowedRooms = List<String>.from(memberData['allowedRooms']);
          notifyListeners();
        }
      } else {
        _allowedRooms = [];
        notifyListeners();
      }
    });
  }

  // 🔹 CREATE HOME (Firestore)
  Future<String?> createHome(String name) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "User not logged in";

      // Check if home name already exists
      final String lowerName = name.toLowerCase();
      final snapshot = await _firestore
          .collection('homes')
          .where('nameLower', isEqualTo: lowerName)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return "This home name is already taken. Please choose another.";
      }

      final String homeCode = const Uuid().v4().substring(0, 6).toUpperCase();
      
      final homeRef = _firestore.collection('homes').doc();
      final String homeId = homeRef.id;

      WriteBatch batch = _firestore.batch();

      // 1. Create Home Document
      batch.set(homeRef, {
        'name': name,
        'nameLower': lowerName,
        'code': homeCode,
        'ownerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Add owner to members sub-collection
      batch.set(homeRef.collection('members').doc(user.uid), {
        'role': 'owner',
        'name': user.displayName ?? 'Owner',
        'email': user.email ?? '',
        'allowedRooms': [], // Owner has access to all
      });

      // 3. Update user document (using set with merge to handle cases where doc might not exist)
      batch.set(_firestore.collection('users').doc(user.uid), {
        'homeId': homeId,
      }, SetOptions(merge: true));

      await batch.commit();

      _homeId = homeId;
      _homeName = name;
      _homeCode = homeCode;
      _ownerId = user.uid;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint("Create Home Error: $e");
      return "Failed to create home: $e";
    }
  }

  // 🔹 JOIN HOME (Firestore)
  Future<String?> joinHome(String code) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "User not logged in";

      final snapshot = await _firestore
          .collection('homes')
          .where('code', isEqualTo: code.toUpperCase())
          .get();

      if (snapshot.docs.isEmpty) return "Invalid Home Code";

      final homeDoc = snapshot.docs.first;
      final homeId = homeDoc.id;

      _pendingHomeId = homeId;
      _isPendingApproval = true;
      notifyListeners();

      // Add to joinRequests sub-collection
      await homeDoc.reference.collection('joinRequests').doc(user.uid).set({
        'status': 'pending',
        'email': user.email ?? 'Unknown Email',
        'name': user.displayName ?? 'Unknown Name',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'pendingHomeId': homeId,
      });

      return null;
    } catch (e) {
      debugPrint("Join Home Error: $e");
      return "Failed to join home. Please try again.";
    }
  }

  // 🔹 GET JOIN REQUESTS (Firestore Stream)
  Stream<QuerySnapshot> getJoinRequests(String homeId) {
    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('joinRequests')
        .snapshots();
  }

  // 🔹 APPROVE JOIN REQUEST (Firestore)
  Future<void> approveJoinRequest(String homeId, String userId, List<String> allowedRoomIds, String name, String email) async {
    try {
      WriteBatch batch = _firestore.batch();
      DocumentReference homeRef = _firestore.collection('homes').doc(homeId);

      // 1. Add to members
      batch.set(homeRef.collection('members').doc(userId), {
        'role': 'guest',
        'name': name,
        'email': email,
        'allowedRooms': allowedRoomIds,
      });

      // 2. Remove from joinRequests
      batch.delete(homeRef.collection('joinRequests').doc(userId));

      // 3. Update user document
      batch.update(_firestore.collection('users').doc(userId), {
        'homeId': homeId,
        'pendingHomeId': FieldValue.delete(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint("Approve Request Error: $e");
    }
  }

  // 🔹 GET HOME MEMBERS (Firestore Stream)
  Stream<QuerySnapshot> getHomeMembers(String homeId) {
    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .snapshots();
  }

  // 🔹 UPDATE MEMBER ROOMS (Firestore)
  Future<void> updateMemberRooms(String homeId, String userId, List<String> allowedRoomIds) async {
    try {
      await _firestore
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(userId)
          .update({'allowedRooms': allowedRoomIds});
    } catch (e) {
      debugPrint("Update Member Rooms Error: $e");
    }
  }

  // 🔹 REMOVE MEMBER (Firestore)
  Future<void> removeMember(String homeId, String userId) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      batch.delete(_firestore.collection('homes').doc(homeId).collection('members').doc(userId));
      batch.update(_firestore.collection('users').doc(userId), {
        'homeId': FieldValue.delete(),
        'pendingHomeId': FieldValue.delete(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint("Remove Member Error: $e");
    }
  }

  // 🔹 DENY JOIN REQUEST (Firestore)
  Future<void> denyJoinRequest(String homeId, String userId) async {
    try {
      WriteBatch batch = _firestore.batch();
      batch.delete(_firestore.collection('homes').doc(homeId).collection('joinRequests').doc(userId));
      batch.update(_firestore.collection('users').doc(userId), {
        'pendingHomeId': FieldValue.delete(),
      });
      await batch.commit();
    } catch (e) {
      debugPrint("Deny Request Error: $e");
    }
  }


  // 🔹 RESET PASSWORD (with detailed error)
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // null = no error
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "user-not-found":
          return "No user found with this email.";
        case "invalid-email":
          return "The email address is not valid.";
        case "missing-email":
          return "Please provide an email.";
        default:
          return "Something went wrong. Try again later.";
      }
    } catch (e) {
      return "Unexpected error: $e";
    }
  }

  // 🔹 AUTO LOGIN CHECK
  Future<void> checkAuthState() async {
    final user = _auth.currentUser;
    if (user != null) {
      _isAuthenticated = true;
      _userEmail = user.email;
      await fetchUserHome();
    } else {
      _isAuthenticated = false;
      _userEmail = null;
      _homeId = null;
      _homeName = null;
      _homeCode = null;
      _ownerId = null;
      _isPendingApproval = false;
      _pendingHomeId = null;
      _allowedRooms = [];
    }
    notifyListeners();
  }

  // 🔹 GOOGLE SIGN IN
  Future<User?> signInWithGoogle() async {
    try {
      final List<String> scopes = ['email', 'profile', 'openid'];
      
      // 1. Initialize (Mandatory in 7.x)
      // Note: 'scopes' is not a parameter for initialize in 7.x
      await GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId,
      );

      // 2. Authenticate
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) return null; // User cancelled

      // 3. Obtain authentication details
      // Note: In 7.x, authentication property is a synchronous getter
      final String? idToken = googleUser.authentication.idToken;

      // 4. Obtain authorization for access token
      final GoogleSignInClientAuthorization? authorization = 
          await googleUser.authorizationClient.authorizationForScopes(scopes);
      final String? accessToken = authorization?.accessToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Sync Google user with Firestore with timeout
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'fullName': userCredential.user!.displayName,
            'email': userCredential.user!.email,
            'homeId': null,
          }).timeout(const Duration(seconds: 10));
        }
      } catch (e) {
        debugPrint("Firestore sync error during Google Sign In: $e");
        // We still return the user because authentication was successful
      }

      _isAuthenticated = true;
      _userEmail = userCredential.user?.email;
      await fetchUserHome();
      notifyListeners();
      
      return userCredential.user;
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      rethrow; 
    }
  }
}
