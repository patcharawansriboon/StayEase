import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<bool> signUpAdmin({
    required String phone,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: '$phone@stayease.app',
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
      await _supabase.from('admins').insert({
        'id': res.user!.id,
        'full_name': fullName,
        'phone': phone,
      });
      print('✅ Admin created: ${res.user!.id}');
      return true;
    } catch (e) {
      print('❌ signUpAdmin Error: $e');
      return false;
    }
  }

  Future<bool> signUpTenant({
    required String phone,
    required String password,
    required String fullName,
    required String dormCode,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: '$phone@stayease.app',
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
      await _supabase.from('tenants').insert({
        'id': res.user!.id,
        'full_name': fullName,
        'phone': phone,
        'dorm_code': dormCode,
        'is_verified': false,
        'status': 'pending',
      });
      print('✅ Tenant created: ${res.user!.id}');
      return true;
    } on AuthApiException catch (e) {
      if (e.message.contains('already') || e.code == 'user_already_exists') {
        print('⚠️ signUpTenant: user already exists');
      }
      print('❌ signUpTenant Error: $e');
      return false;
    } catch (e) {
      print('❌ signUpTenant Error: $e');
      return false;
    }
  }

  Future<bool> signUpRoommate({
    required String phone,
    required String password,
    required String fullName,
    required String inviteCode,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: '$phone@stayease.app',
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );
      await _supabase.from('roommates').insert({
        'id': res.user!.id,
        'full_name': fullName,
        'phone': phone,
        'invite_code': inviteCode,
        'is_verified': false,
        'status': 'pending',
      });
      print('✅ Roommate created: ${res.user!.id}');
      return true;
    } on AuthApiException catch (e) {
      if (e.message.contains('already') || e.code == 'user_already_exists') {
        print('⚠️ signUpRoommate: user already exists');
      }
      print('❌ signUpRoommate Error: $e');
      return false;
    } catch (e) {
      print('❌ signUpRoommate Error: $e');
      return false;
    }
  }

  Future<Map<String, String>> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: '$phone@stayease.app',
        password: password,
      );
      final uid = _supabase.auth.currentUser!.id;

      final admin = await _supabase
          .from('admins')
          .select('full_name, phone')
          .eq('id', uid)
          .maybeSingle();
      if (admin != null) {
        return {
          'role': 'admin',
          'full_name': (admin['full_name'] as String?) ?? '',
          'phone': admin['phone']?.toString() ?? '',
        };
      }

      final tenant = await _supabase
          .from('tenants')
          .select('full_name, phone')
          .eq('id', uid)
          .maybeSingle();
      if (tenant != null) {
        return {
          'role': 'tenant',
          'full_name': (tenant['full_name'] as String?) ?? '',
          'phone': tenant['phone']?.toString() ?? '',
        };
      }

      final roommate = await _supabase
          .from('roommates')
          .select('full_name, phone')
          .eq('id', uid)
          .maybeSingle();
      if (roommate != null) {
        return {
          'role': 'roommate',
          'full_name': (roommate['full_name'] as String?) ?? '',
          'phone': roommate['phone']?.toString() ?? '',
        };
      }

      return {'role': 'unknown', 'full_name': '', 'phone': ''};
    } catch (e) {
      print('❌ signIn Error: $e');
      return {'role': 'error', 'full_name': '', 'phone': ''};
    }
  }

  Future<Map<String, String>?> getUserData() async {
    try {
      final uid = _supabase.auth.currentUser!.id;
      final tables = [
        {'table': 'admins', 'role': 'admin'},
        {'table': 'tenants', 'role': 'tenant'},
        {'table': 'roommates', 'role': 'roommate'},
      ];
      for (final t in tables) {
        final result = await _supabase
            .from(t['table'] as String)
            .select('full_name, phone')
            .eq('id', uid)
            .maybeSingle();
        if (result != null) {
          return {
            'full_name': (result['full_name'] as String?) ?? '',
            'phone': result['phone']?.toString() ?? '',
            'role': t['role'] as String,
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ getUserData Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  bool isLoggedIn() => _supabase.auth.currentUser != null;
  String? getUserId() => _supabase.auth.currentUser?.id;
}
