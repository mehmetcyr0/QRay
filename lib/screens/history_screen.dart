import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../widgets/qr_code_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadQrCodes();
  }

  Future<void> _loadQrCodes() async {
    final supabaseService =
        Provider.of<SupabaseService>(context, listen: false);
    await supabaseService.loadQrCodes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('QR Kod Geçmişi'),
        elevation: 0,
      ),
      body: Consumer<SupabaseService>(
        builder: (context, supabaseService, child) {
          if (supabaseService.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          if (supabaseService.qrCodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz QR kod oluşturmadınız',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR kod tarayarak veya oluşturarak başlayın',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadQrCodes,
            color: theme.colorScheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: supabaseService.qrCodes.length,
              itemBuilder: (context, index) {
                final qrCode = supabaseService.qrCodes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QrCodeItem(qrCode: qrCode),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
