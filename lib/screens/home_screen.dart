import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/qr_service.dart';
import '../services/supabase_service.dart';
import 'scanner_screen.dart';
import 'create_qr_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final QrService _qrService;
  late final SupabaseService _supabaseService;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _qrService = Provider.of<QrService>(context, listen: false);
    _supabaseService = Provider.of<SupabaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _supabaseService.loadQrCodes();
  }

  Future<void> _handleScan() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const ScannerScreen()),
      );

      if (result == null || !mounted) return;

      await _qrService.scanQrCode(result);
      await _supabaseService.loadQrCodes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR kod başarıyla tarandı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _handleCreateQr() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateQrScreen()),
      );
      if (!mounted) return;
      await _supabaseService.loadQrCodes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _handleHistory() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );
      if (!mounted) return;
      await _supabaseService.loadQrCodes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _handleBusinessCard() async {
    final formKey = GlobalKey<FormState>();
    final cardInfo = {
      'isim': '',
      'telefon': '',
      'eposta': '',
      'sirket': '',
      'unvan': '',
      'adres': '',
      'websitesi': '',
    };

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kartvizit Bilgileri'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad *',
                      hintText: 'Mehmet Çayır',
                      helperText: 'Zorunlu alan',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen adınızı ve soyadınızı girin';
                      }
                      return null;
                    },
                    onSaved: (value) => cardInfo['isim'] = value ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Telefon *',
                      hintText: '+90 555 123 4567',
                      helperText: 'Zorunlu alan',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen telefon numaranızı girin';
                      }
                      return null;
                    },
                    onSaved: (value) => cardInfo['telefon'] = value ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'E-posta *',
                      hintText: 'ornek@email.com',
                      helperText: 'Zorunlu alan',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen e-posta adresinizi girin';
                      }
                      if (!value.contains('@')) {
                        return 'Lütfen geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                    onSaved: (value) => cardInfo['eposta'] = value ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Şirket',
                      hintText: 'Şirket Adı',
                      helperText: 'İsteğe bağlı',
                    ),
                    onSaved: (value) => cardInfo['sirket'] = value ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Ünvan',
                      hintText: 'Yazılım Geliştirici',
                      helperText: 'İsteğe bağlı',
                    ),
                    onSaved: (value) => cardInfo['unvan'] = value ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Adres',
                      hintText: 'İş adresi',
                      helperText: 'İsteğe bağlı',
                    ),
                    maxLines: 2,
                    onSaved: (value) => cardInfo['adres'] = value ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Web Sitesi',
                      hintText: 'https://example.com',
                      helperText: 'İsteğe bağlı',
                    ),
                    keyboardType: TextInputType.url,
                    onSaved: (value) => cardInfo['websitesi'] = value ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  Navigator.pop(context, true);
                }
              },
              child: const Text('QR Kod Oluştur'),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        final vcard = '''BEGIN:VCARD
VERSION:3.0
N:${cardInfo['isim']}
FN:${cardInfo['isim']}
TEL;TYPE=CELL:${cardInfo['telefon']}
EMAIL:${cardInfo['eposta']}
ORG:${cardInfo['sirket']}
TITLE:${cardInfo['unvan']}
ADR;TYPE=WORK:;;${cardInfo['adres']}
URL:${cardInfo['websitesi']}
END:VCARD''';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateQrScreen(initialData: vcard),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kartvizit QR kodu oluşturulurken bir hata oluştu'),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    try {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Çıkış Yap'),
            ),
          ],
        ),
      );

      if (shouldLogout == true && mounted) {
        await _performLogout();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _performLogout() async {
    try {
      setState(() => _supabaseService.setLoading(true));

      await _authService.signOut();
      await _supabaseService.clearData();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılırken hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _supabaseService.setLoading(false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRay'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Consumer<SupabaseService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QR Kod İşlemleri',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildMenuButton(
                        icon: Icons.qr_code_scanner,
                        label: 'QR Kod Tara',
                        onPressed: _handleScan,
                      ),
                      _buildMenuButton(
                        icon: Icons.qr_code,
                        label: 'QR Kod Oluştur',
                        onPressed: _handleCreateQr,
                      ),
                      _buildMenuButton(
                        icon: Icons.history,
                        label: 'Geçmiş',
                        onPressed: _handleHistory,
                      ),
                      _buildMenuButton(
                        icon: Icons.contact_page,
                        label: 'Kartvizit QR',
                        onPressed: _handleBusinessCard,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
