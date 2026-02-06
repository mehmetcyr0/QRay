import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  Timer? _debounceTimer;
  bool _torchEnabled = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      controller.start();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR kod taramak için kamera izni gerekiyor'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamera izni alınırken bir hata oluştu'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_isProcessing) return;

      try {
        final List<Barcode> barcodes = capture.barcodes;
        if (barcodes.isEmpty) return;

        final String? code = barcodes.first.rawValue;
        if (code == null || code.isEmpty) return;

        setState(() => _isProcessing = true);

        if (!mounted) return;

        if (_isValidUrl(code)) {
          await _handleUrl(code);
        } else if (_isVCard(code)) {
          await _showBusinessCardDialog(code);
        } else {
          await _showContentDialog(code);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    });
  }

  bool _isValidUrl(String text) {
    try {
      final uri = Uri.parse(text.toLowerCase());
      if (uri.hasScheme && uri.host.isNotEmpty) return true;

      return text.startsWith('www.') ||
          (text.contains('.') &&
              !text.contains(' ') &&
              !text.contains('\n') &&
              text.split('.').length >= 2 &&
              text.split('.').every((part) => part.isNotEmpty));
    } catch (_) {
      return false;
    }
  }

  bool _isVCard(String text) {
    return text.trim().startsWith('BEGIN:VCARD') &&
        text.trim().endsWith('END:VCARD');
  }

  Map<String, String> _parseVCard(String vcard) {
    final cardInfo = <String, String>{};
    try {
      final lines = vcard.split('\n');

      for (var line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty ||
            trimmedLine.startsWith('BEGIN:') ||
            trimmedLine.startsWith('END:')) {
          continue;
        }

        if (trimmedLine.startsWith('FN:')) {
          cardInfo['name'] = trimmedLine.substring(3).trim();
        } else if (trimmedLine.startsWith('N:')) {
          final nameParts = trimmedLine.substring(2).split(';');
          if (nameParts.length >= 2) {
            final lastName = nameParts[0].trim();
            final firstName = nameParts[1].trim();
            if (cardInfo['name'] == null || cardInfo['name']!.isEmpty) {
              cardInfo['name'] = '$firstName $lastName'.trim();
            }
          }
        } else if (trimmedLine.startsWith('TEL')) {
          final telParts = trimmedLine.split(':');
          if (telParts.length > 1) {
            final phone =
                telParts.last.trim().replaceAll(RegExp(r'[^\d+]'), '');
            if (phone.isNotEmpty) {
              cardInfo['phone'] = phone;
            }
          }
        } else if (trimmedLine.startsWith('EMAIL')) {
          final emailParts = trimmedLine.split(':');
          if (emailParts.length > 1) {
            final email = emailParts.last.trim();
            if (email.isNotEmpty && !cardInfo.containsKey('email')) {
              cardInfo['email'] = email;
            }
          }
        } else if (trimmedLine.startsWith('ORG:')) {
          cardInfo['company'] = trimmedLine.substring(4).trim();
        } else if (trimmedLine.startsWith('TITLE:')) {
          cardInfo['title'] = trimmedLine.substring(6).trim();
        } else if (trimmedLine.startsWith('ADR')) {
          final adrParts = trimmedLine.split(':');
          if (adrParts.length > 1) {
            final address = adrParts.last.trim().replaceAll(';', ', ');
            if (address.isNotEmpty && !cardInfo.containsKey('address')) {
              cardInfo['address'] = address;
            }
          }
        } else if (trimmedLine.startsWith('URL')) {
          final urlParts = trimmedLine.split(':');
          if (urlParts.length > 1) {
            final url = urlParts.last.trim();
            if (url.isNotEmpty && !cardInfo.containsKey('website')) {
              cardInfo['website'] = url;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('vCard parse hatası: $e');
    }
    return cardInfo;
  }

  Future<void> _handleUrl(String code) async {
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900], // Koyu arka plan
        title: const Text(
          'Web Sitesi Bulundu',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aşağıdaki web sitesi ile ne yapmak istersiniz?',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), // Çok koyu gri
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[850]!, // Koyu kenarlık
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'close'),
            child: Text(
              'Kapat',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Link panoya kopyalandı',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.grey[850],
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              Navigator.pop(context, 'copy');
            },
            child: const Text(
              'Kopyala',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'open'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_browser, size: 20),
                SizedBox(width: 8),
                Text('Tarayıcıda Aç'),
              ],
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    switch (result) {
      case 'open':
        try {
          String urlString = code;
          if (urlString.startsWith('www.')) {
            urlString = 'https://$urlString';
          } else if (!urlString.startsWith('http://') &&
              !urlString.startsWith('https://')) {
            urlString = 'https://$urlString';
          }

          final uri = Uri.parse(urlString);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (mounted) Navigator.pop(context);
          } else {
            throw 'URL açılamadı';
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Web sitesi açılamadı'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;

      case 'copy':
        Navigator.pop(context, code);
        break;

      case 'close':
        Navigator.pop(context);
        break;
    }
  }

  Future<void> _showBusinessCardDialog(String vcard) async {
    if (!mounted) return;

    final cardInfo = _parseVCard(vcard);

    if (cardInfo.isEmpty) {
      await _showContentDialog(vcard);
      return;
    }

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[700]!,
                        Colors.blue[900]!,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cardInfo['name'] ?? 'İsimsiz',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (cardInfo['title'] != null ||
                          cardInfo['company'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          [cardInfo['title'], cardInfo['company']]
                              .where((e) => e != null && e.isNotEmpty)
                              .join(' - '),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (cardInfo['phone'] != null)
                        _buildInfoTile(
                          icon: Icons.phone,
                          label: 'Telefon',
                          value: cardInfo['phone']!,
                          onTap: () async {
                            final uri = Uri.parse('tel:${cardInfo['phone']}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      if (cardInfo['email'] != null)
                        _buildInfoTile(
                          icon: Icons.email,
                          label: 'E-posta',
                          value: cardInfo['email']!,
                          onTap: () async {
                            final uri =
                                Uri.parse('mailto:${cardInfo['email']}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      if (cardInfo['company'] != null &&
                          cardInfo['title'] == null)
                        _buildInfoTile(
                          icon: Icons.business,
                          label: 'Şirket',
                          value: cardInfo['company']!,
                        ),
                      if (cardInfo['address'] != null)
                        _buildInfoTile(
                          icon: Icons.location_on,
                          label: 'Adres',
                          value: cardInfo['address']!,
                        ),
                      if (cardInfo['website'] != null)
                        _buildInfoTile(
                          icon: Icons.language,
                          label: 'Web Sitesi',
                          value: cardInfo['website']!,
                          onTap: () async {
                            String url = cardInfo['website']!;
                            if (!url.startsWith('http://') &&
                                !url.startsWith('https://')) {
                              url = 'https://$url';
                            }
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: vcard));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kartvizit panoya kopyalandı'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Kopyala'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[300],
                        ),
                      ),
                      const VerticalDivider(color: Colors.grey, thickness: 1),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context, 'close'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Kapat'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == 'close' && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final tile = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue[300], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[600],
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: tile,
      );
    }
    return tile;
  }

  Future<void> _showContentDialog(String content) async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'QR Kod İçeriği',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Taranan içerik:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[850]!,
                    width: 1,
                  ),
                ),
                child: SelectableText(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'İçeriği seçmek için metne uzun basın',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Kapat',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'İçerik panoya kopyalandı',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.grey[850],
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
              Navigator.pop(context, true);
            },
            child: const Text(
              'Kopyala',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Tamam',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod Tara'),
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              controller.toggleTorch();
              setState(() {
                _torchEnabled = !_torchEnabled;
              });
            },
            tooltip: 'Flaş',
          ),
          IconButton(
            icon: Icon(_cameraFacing == CameraFacing.front
                ? Icons.camera_front
                : Icons.camera_rear),
            onPressed: () {
              controller.switchCamera();
              setState(() {
                _cameraFacing = _cameraFacing == CameraFacing.front
                    ? CameraFacing.back
                    : CameraFacing.front;
              });
            },
            tooltip: 'Kamera Değiştir',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleDetection,
            scanWindow: Rect.fromCenter(
              center: Offset(
                MediaQuery.of(context).size.width / 2,
                MediaQuery.of(context).size.height / 2,
              ),
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          CustomPaint(
            painter: ScannerOverlay(),
            child: const SizedBox.expand(),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.width * 0.8,
    );

    canvas.drawRect(scanArea, paint);

    final cornerSize = scanArea.width * 0.1;
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Sol üst köşe
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft.translate(cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft.translate(0, cornerSize),
      cornerPaint,
    );

    // Sağ üst köşe
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight.translate(-cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight.translate(0, cornerSize),
      cornerPaint,
    );

    // Sol alt köşe
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft.translate(cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft.translate(0, -cornerSize),
      cornerPaint,
    );

    // Sağ alt köşe
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight.translate(-cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight.translate(0, -cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
