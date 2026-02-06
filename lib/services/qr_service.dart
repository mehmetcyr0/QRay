import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class QrService extends ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String formatQrContent(String content) {
    if (content.startsWith('BEGIN:VCARD')) {
      try {
        final lines = content.split('\n');
        final cardInfo = <String, String>{};

        for (var line in lines) {
          if (line.startsWith('FN:')) {
            cardInfo['Ad Soyad'] = line.substring(3);
          } else if (line.startsWith('TEL')) {
            cardInfo['Telefon'] = line.split(':').last;
          } else if (line.startsWith('EMAIL:')) {
            cardInfo['E-posta'] = line.substring(6);
          } else if (line.startsWith('ORG:')) {
            cardInfo['Şirket'] = line.substring(4);
          } else if (line.startsWith('TITLE:')) {
            cardInfo['Ünvan'] = line.substring(6);
          } else if (line.startsWith('ADR')) {
            cardInfo['Adres'] = line.split(':').last;
          } else if (line.startsWith('URL:')) {
            cardInfo['Web Sitesi'] = line.substring(4);
          }
        }

        if (cardInfo.isNotEmpty) {
          final buffer = StringBuffer();
          buffer.writeln('📇 Kartvizit Bilgileri:');
          buffer.writeln('------------------------');

          cardInfo.forEach((key, value) {
            if (value.isNotEmpty) {
              buffer.writeln('$key: $value');
            }
          });

          return buffer.toString();
        }
      } catch (e) {
        debugPrint('vCard ayrıştırma hatası: $e');
      }
    }
    return content;
  }

  Future<void> scanQrCode(String content) async {
    try {
      _setLoading(true);
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı oturumu bulunamadı');

      await _supabaseClient.from(Constants.qrCodesTable).insert({
        'content': content,
        'user_id': userId,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('QR kod tarama hatası: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> shareQrCode(BuildContext context, String content) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png';

      // Daha yüksek çözünürlükte QR kod oluştur
      final qrImage = await QrPainter(
        data: content,
        version: QrVersions.auto,
        gapless: true,
      ).toImageData(512); // 512x512 piksel

      if (qrImage == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR kod görseli oluşturulamadı'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final file = File(tempPath);
      await file.writeAsBytes(qrImage.buffer.asUint8List());

      if (!context.mounted) return;

      // PNG dosyasını paylaş
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'QR Kod: $content',
        subject: 'QR Kod',
      );

      // Dosyayı temizle (kısa bir gecikme ile, paylaşım tamamlanana kadar)
      Future.delayed(const Duration(seconds: 2), () {
        try {
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          debugPrint('Geçici dosya silinirken hata: $e');
        }
      });
    } catch (e) {
      debugPrint('QR kod paylaşım hatası: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım hatası: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> saveQrCodeToGallery(
      BuildContext context, String content) async {
    try {
      _setLoading(true);

      // Galeri izni kontrolü
      Permission? permission;
      if (Platform.isAndroid) {
        // Android 13+ için photos, eski versiyonlar için storage
        permission = Permission.photos;
      } else if (Platform.isIOS) {
        permission = Permission.photos;
      }

      if (permission != null) {
        final status = await permission.status;
        if (!status.isGranted) {
          final result = await permission.request();
          if (!result.isGranted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Galeriye kaydetmek için izin gerekiyor'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return null;
          }
        }
      }

      // QR kod görselini oluştur
      final qrImage = await QrPainter(
        data: content,
        version: QrVersions.auto,
        gapless: true,
      ).toImageData(512); // Daha yüksek çözünürlük

      if (qrImage == null) {
        return null;
      }

      // Byte verilerini al
      final Uint8List bytes = qrImage.buffer.asUint8List();

      // Galeriye kaydet
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'QR_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        return result['filePath'] as String?;
      } else {
        debugPrint('Galeriye kaydetme başarısız: $result');
        return null;
      }
    } catch (e) {
      debugPrint('QR kod kaydetme hatası: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
}
