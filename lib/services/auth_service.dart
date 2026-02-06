import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _lastError;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _supabaseClient.auth.currentUser != null;
  User? get currentUser => _supabaseClient.auth.currentUser;
  String? get lastError => _lastError;

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    _lastError = error;
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        _setError(Constants.errorInvalidCredentials);
        return false;
      }

      return true;
    } on AuthException catch (e) {
      String errorMessage;
      switch (e.message) {
        case 'Invalid login credentials':
          errorMessage = Constants.errorInvalidCredentials;
          break;
        case 'Email not confirmed':
          errorMessage = Constants.errorEmailNotConfirmed;
          break;
        default:
          errorMessage = '${Constants.errorAuth}: ${e.message}';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError(Constants.errorUnexpected);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up with email and password
  Future<bool> signUp(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        _setError(Constants.errorUnexpected);
        return false;
      }

      _setError(Constants.successRegister);
      return true;
    } on AuthException catch (e) {
      String errorMessage;
      switch (e.message) {
        case 'User already registered':
          errorMessage = Constants.errorUserExists;
          break;
        case 'Password should be at least 6 characters':
          errorMessage = Constants.errorWeakPassword;
          break;
        default:
          errorMessage = '${Constants.errorAuth}: ${e.message}';
      }
      _setError(errorMessage);
      return false;
    } catch (e) {
      _setError(Constants.errorUnexpected);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _supabaseClient.auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Çıkış yapma hatası: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Initialize auth state
  Future<void> initializeAuthState() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      // Listen to auth state changes
      _supabaseClient.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;

        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.signedOut ||
            event == AuthChangeEvent.userUpdated) {
          // Use Future.microtask to ensure we're not calling notifyListeners during build
          Future.microtask(() => notifyListeners());
        }
      });

      _isInitialized = true;
    } catch (e) {
      _setError("Failed to initialize authentication. Please restart the app.");
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
