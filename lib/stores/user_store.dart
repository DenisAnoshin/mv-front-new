import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProfile {
  final String id;
  final String phone;
  final String displayName;
  final String? avatarUrl;
  // Extended fields
  final String? username;
  final DateTime? registeredAt;
  final String? bio;
  final bool? isPremium;

  const UserProfile({
    required this.id,
    required this.phone,
    required this.displayName,
    this.avatarUrl,
    this.username,
    this.registeredAt,
    this.bio,
    this.isPremium,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'phone': phone,
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (username != null) 'username': username,
        if (registeredAt != null) 'registeredAt': registeredAt!.toIso8601String(),
        if (bio != null) 'bio': bio,
        if (isPremium != null) 'isPremium': isPremium,
      };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id'] as String,
        phone: m['phone'] as String? ?? '',
        displayName: m['displayName'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String?,
        username: m['username'] as String?,
        registeredAt: m['registeredAt'] != null ? DateTime.tryParse(m['registeredAt'] as String) : null,
        bio: m['bio'] as String?,
        isPremium: m['isPremium'] as bool?,
      );
}

class UserStore extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _profileKey = 'auth_profile_json';

  UserProfile? _currentUser;
  String? _authToken;
  // In-memory users cache (includes current user and known peers)
  final Map<String, UserProfile> _usersById = <String, UserProfile>{};

  // Pending login state
  String? _pendingPhone;

  UserProfile? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoggedIn => _authToken != null && _currentUser != null;

  // Read-only view over cached users
  Map<String, UserProfile> get usersById => Map.unmodifiable(_usersById);
  UserProfile? getUserById(String userId) => _usersById[userId];

  void upsertUser(UserProfile user) {
    _usersById[user.id] = user;
    notifyListeners();
  }

  void upsertUsers(Iterable<UserProfile> users) {
    bool changed = false;
    for (final u in users) {
      final existing = _usersById[u.id];
      if (existing == null || existing != u) {
        _usersById[u.id] = u;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final profileJson = prefs.getString(_profileKey);
    if (token != null && token.isNotEmpty) {
      _authToken = token;
      if (profileJson != null && profileJson.isNotEmpty) {
        try {
          final map = json.decode(profileJson) as Map<String, dynamic>;
          _currentUser = UserProfile.fromMap(map);
        } catch (_) {
          _currentUser = _mockUserFromToken(token);
        }
      } else {
        _currentUser = _mockUserFromToken(token);
      }
      // Ensure current user is present in cache
      _usersById[_currentUser!.id] = _currentUser!;
      notifyListeners();
    }
  }

  // Step 1: request login code (mock)
  Future<bool> requestLoginCode(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _pendingPhone = _normalizePhone(phoneNumber);
    return true;
  }

  // Step 2: verify code (mock). Code '000000' means success
  Future<bool> verifySmsCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_pendingPhone == null) return false;
    if (code.trim() != '000000') return false;

    final normalized = _pendingPhone!;
    final token = 'mock-token-$normalized';
    final profile = _generateMockProfileForPhone(normalized);

    final prefs = await SharedPreferences.getInstance();
    _authToken = token;
    _currentUser = profile;
    _usersById[_currentUser!.id] = _currentUser!;

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_profileKey, json.encode(profile.toMap()));

    _pendingPhone = null;
    notifyListeners();
    return true;
  }

  // Legacy single-step login preserved for compatibility (unused by new UI)
  Future<bool> loginWithPhoneMock(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final normalized = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    _authToken = 'mock-token-$normalized';
    _currentUser = _generateMockProfileForPhone('+$normalized');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _authToken!);
    await prefs.setString(_profileKey, json.encode(_currentUser!.toMap()));

    // Put current user into cache
    _usersById[_currentUser!.id] = _currentUser!;

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _authToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_profileKey);
    notifyListeners();
  }

  // Helpers
  String _normalizePhone(String raw) => '+${raw.replaceAll(RegExp(r'[^0-9]'), '')}';

  UserProfile _mockUserFromToken(String token) {
    final digits = RegExp(r'(\d+)').firstMatch(token)?.group(1) ?? '0000000000';
    return _generateMockProfileForPhone('+${digits}');
  }

  UserProfile _generateMockProfileForPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final id = 'u_$digits';
    final handle = 'user_${digits.substring(digits.length - 4)}';
    final display = 'User ${digits.substring(digits.length - 4)}';
    final registered = DateTime.now().subtract(const Duration(days: 120));
    return UserProfile(
      id: id,
      phone: phone,
      displayName: display,
      username: handle,
      registeredAt: registered,
      bio: 'Hello there! I am using MV.',
      isPremium: digits.hashCode % 5 == 0,
      avatarUrl: null,
    );
  }
} 