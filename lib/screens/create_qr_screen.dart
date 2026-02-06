import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/qr_service.dart';

class CreateQrScreen extends StatefulWidget {
  final String? initialData;

  const CreateQrScreen({
    super.key,
    this.initialData,
  });

  @override
  State<CreateQrScreen> createState() => _CreateQrScreenState();
}

class _CreateQrScreenState extends State<CreateQrScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contentController;
  String? _qrData;
  bool _isLoading = false;
  
  // QR kod özelleştirme değişkenleri
  Color _qrColor = Colors.black;
  Color _backgroundColor = Colors.white;
  Color _eyeColor = Colors.black;
  QrEyeShape _eyeShape = QrEyeShape.square;
  QrDataModuleShape _dataModuleShape = QrDataModuleShape.square;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialData);
    if (widget.initialData != null) {
      setState(() {
        _qrData = widget.initialData;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _generateQr() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _qrData = _contentController.text;
      });
    }
  }

  Future<void> _saveQr() async {
    if (_qrData == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final qrService = Provider.of<QrService>(context, listen: false);
      await qrService.scanQrCode(_qrData!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR kod başarıyla kaydedildi')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Kod Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.initialData == null) ...[
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'QR Kod İçeriği',
                    hintText: 'Metin, URL veya başka bir içerik girin',
                    helperText: 'QR kodunun içereceği bilgiyi girin',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen bir içerik girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _generateQr,
                  child: const Text('QR Kod Oluştur'),
                ),
              ],
              if (_qrData != null) ...[
                const SizedBox(height: 32),
                // Özelleştirme başlığı
                Row(
                  children: [
                    const Icon(Icons.palette),
                    const SizedBox(width: 8),
                    Text(
                      'QR Kod Özelleştirme',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Özelleştirme seçenekleri
                _buildCustomizationOptions(),
                const SizedBox(height: 24),
                // QR Kod Önizleme
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      // Transparan arka plan için dama tahtası deseni
                      color: _backgroundColor.alpha == 0
                          ? Colors.grey.withValues(alpha: 0.1)
                          : _backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      maxWidth: 280,
                      maxHeight: 280,
                    ),
                    child: Stack(
                      children: [
                        // Transparan arka plan için dama tahtası deseni
                        if (_backgroundColor.alpha == 0)
                          CustomPaint(
                            size: const Size(248, 248),
                            painter: _CheckerboardPainter(),
                          ),
                        QrImageView(
                          data: _qrData!,
                          version: QrVersions.auto,
                          size: 248,
                          backgroundColor: _backgroundColor,
                          eyeStyle: QrEyeStyle(
                            eyeShape: _eyeShape,
                            color: _eyeColor,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: _dataModuleShape,
                            color: _qrColor,
                          ),
                          padding: EdgeInsets.zero,
                          gapless: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (!_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ElevatedButton.icon(
                      onPressed: _saveQr,
                      icon: const Icon(Icons.save),
                      label: const Text('Kaydet'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizationOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // QR Kod Rengi
        _buildColorPicker(
          title: 'QR Kod Rengi',
          currentColor: _qrColor,
          onColorChanged: (color) {
            setState(() {
              _qrColor = color;
            });
          },
        ),
        const SizedBox(height: 16),
        // Arka Plan Rengi (transparan seçeneği ile)
        _buildColorPicker(
          title: 'Arka Plan Rengi',
          currentColor: _backgroundColor,
          onColorChanged: (color) {
            setState(() {
              _backgroundColor = color;
            });
          },
          allowTransparent: true,
        ),
        const SizedBox(height: 16),
        // Köşe Kare Rengi
        _buildColorPicker(
          title: 'Köşe Kare Rengi',
          currentColor: _eyeColor,
          onColorChanged: (color) {
            setState(() {
              _eyeColor = color;
            });
          },
        ),
        const SizedBox(height: 16),
        // Köşe Kare Şekli
        _buildShapeSelector(
          title: 'Köşe Kare Şekli',
          currentShape: _eyeShape,
          options: [
            {'value': QrEyeShape.square, 'label': 'Kare', 'icon': Icons.crop_square},
            {'value': QrEyeShape.circle, 'label': 'Yuvarlak', 'icon': Icons.radio_button_unchecked},
          ],
          onShapeChanged: (shape) {
            setState(() {
              _eyeShape = shape as QrEyeShape;
            });
          },
        ),
        const SizedBox(height: 16),
        // Veri Modül Şekli
        _buildShapeSelector(
          title: 'Veri Modül Şekli',
          currentShape: _dataModuleShape,
          options: [
            {'value': QrDataModuleShape.square, 'label': 'Kare', 'icon': Icons.crop_square},
            {'value': QrDataModuleShape.circle, 'label': 'Yuvarlak', 'icon': Icons.circle},
          ],
          onShapeChanged: (shape) {
            setState(() {
              _dataModuleShape = shape as QrDataModuleShape;
            });
          },
        ),
        const SizedBox(height: 16),
        // Hızlı Renk Seçenekleri
        _buildQuickColorPresets(),
      ],
    );
  }

  Widget _buildColorPicker({
    required String title,
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
    bool allowTransparent = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (context) => _ColorPickerDialog(
                    currentColor: currentColor,
                    title: title,
                  ),
                );
                if (color != null) {
                  onColorChanged(color);
                }
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.colorize, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (allowTransparent)
                    _buildTransparentOption(currentColor, onColorChanged),
                  _buildColorOption(Colors.black, currentColor, onColorChanged),
                  _buildColorOption(Colors.blue, currentColor, onColorChanged),
                  _buildColorOption(Colors.red, currentColor, onColorChanged),
                  _buildColorOption(Colors.green, currentColor, onColorChanged),
                  _buildColorOption(Colors.orange, currentColor, onColorChanged),
                  _buildColorOption(Colors.purple, currentColor, onColorChanged),
                  _buildColorOption(Colors.pink, currentColor, onColorChanged),
                  _buildColorOption(Colors.teal, currentColor, onColorChanged),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorOption(
    Color color,
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) {
    final isSelected = color.value == currentColor.value;
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                size: 18,
              )
            : null,
      ),
    );
  }

  Widget _buildTransparentOption(
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) {
    final isSelected = currentColor.alpha == 0;
    return GestureDetector(
      onTap: () => onColorChanged(Colors.transparent),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Çapraz çizgiler (transparan göstergesi)
            CustomPaint(
              size: const Size(32, 32),
              painter: _TransparentPatternPainter(),
            ),
            if (isSelected)
              const Center(
                child: Icon(Icons.check, color: Colors.black, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeSelector({
    required String title,
    required dynamic currentShape,
    required List<Map<String, dynamic>> options,
    required ValueChanged<dynamic> onShapeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((option) {
            final isSelected = option['value'] == currentShape;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton.icon(
                  onPressed: () => onShapeChanged(option['value']),
                  icon: Icon(
                    option['icon'] as IconData,
                    size: 18,
                  ),
                  label: Text(option['label'] as String),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    foregroundColor: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickColorPresets() {
    final presets = [
      {'name': 'Klasik', 'qr': Colors.black, 'bg': Colors.white, 'eye': Colors.black},
      {'name': 'Mavi', 'qr': Colors.blue, 'bg': Colors.white, 'eye': Colors.blue},
      {'name': 'Kırmızı', 'qr': Colors.red, 'bg': Colors.white, 'eye': Colors.red},
      {'name': 'Yeşil', 'qr': Colors.green, 'bg': Colors.white, 'eye': Colors.green},
      {'name': 'Koyu', 'qr': Colors.white, 'bg': Colors.black, 'eye': Colors.white},
      {'name': 'Mor', 'qr': Colors.purple, 'bg': Colors.white, 'eye': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Şablonlar',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            return InkWell(
              onTap: () {
                setState(() {
                  _qrColor = preset['qr'] as Color;
                  _backgroundColor = preset['bg'] as Color;
                  _eyeColor = preset['eye'] as Color;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  preset['name'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Renk seçici dialog
class _ColorPickerDialog extends StatefulWidget {
  final Color currentColor;
  final String? title;

  const _ColorPickerDialog({
    required this.currentColor,
    this.title,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  final List<Color> _colors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renk Seç'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seçili renk önizleme
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: _selectedColor.alpha == 0
                    ? Colors.grey.withValues(alpha: 0.1)
                    : _selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Stack(
                children: [
                  if (_selectedColor.alpha == 0)
                    CustomPaint(
                      size: const Size(double.infinity, 60),
                      painter: _CheckerboardPainter(),
                    ),
                  Center(
                    child: Text(
                      _selectedColor.alpha == 0 ? 'Transparan' : 'Seçili Renk',
                      style: TextStyle(
                        color: _selectedColor.alpha == 0
                            ? Colors.black
                            : (_selectedColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Transparan seçeneği (sadece arka plan için)
            if (widget.title == 'Arka Plan Rengi') ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = Colors.transparent;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor.alpha == 0
                          ? Colors.black
                          : Colors.grey.withValues(alpha: 0.3),
                      width: _selectedColor.alpha == 0 ? 3 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(50, 50),
                        painter: _TransparentPatternPainter(),
                      ),
                      if (_selectedColor.alpha == 0)
                        const Center(
                          child: Icon(Icons.check, color: Colors.black, size: 24),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Renk paleti
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('Seç'),
        ),
      ],
    );
  }
}

// Transparan arka plan için dama tahtası deseni
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 10.0;
    final paint1 = Paint()..color = Colors.white;
    final paint2 = Paint()..color = Colors.grey.withValues(alpha: 0.2);

    for (var y = 0.0; y < size.height; y += tileSize) {
      for (var x = 0.0; x < size.width; x += tileSize) {
        final isEven = ((x ~/ tileSize) + (y ~/ tileSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tileSize, tileSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Transparan seçeneği için çapraz çizgiler
class _TransparentPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    // Çapraz çizgiler
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
