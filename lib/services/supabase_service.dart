import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/qr_code_model.dart';
import '../utils/constants.dart';

class SupabaseService extends ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  bool _isLoading = false;
  List<QrCodeModel> _qrCodes = [];

  bool get isLoading => _isLoading;
  List<QrCodeModel> get qrCodes => _qrCodes;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadQrCodes() async {
    try {
      setLoading(true);
      final response = await _supabaseClient
          .from(Constants.qrCodesTable)
          .select()
          .order('created_at', ascending: false);

      _qrCodes =
          (response as List).map((item) => QrCodeModel.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('QR kodları yüklenirken hata: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  // Get current user
  User? get currentUser => _supabaseClient.auth.currentUser;

  // Save QR code
  Future<void> saveQrCode(String content) async {
    try {
      await _supabaseClient.from(Constants.qrCodesTable).insert({
        'user_id': currentUser?.id,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save QR code: $e');
    }
  }

  // Delete QR code
  Future<void> deleteQrCode(String id) async {
    try {
      await _supabaseClient
          .from(Constants.qrCodesTable)
          .delete()
          .eq('id', id)
          .eq('user_id', currentUser!.id);
    } catch (e) {
      throw Exception('Failed to delete QR code: $e');
    }
  }

  // Check if QR code belongs to user
  Future<bool> isQrCodeBelongsToUser(String content) async {
    try {
      final response = await _supabaseClient
          .from(Constants.qrCodesTable)
          .select()
          .eq('user_id', currentUser!.id)
          .eq('content', content);

      return (response as List).isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check QR code: $e');
    }
  }

  Future<void> clearData() async {
    _qrCodes = [];
    notifyListeners();
  }
}
