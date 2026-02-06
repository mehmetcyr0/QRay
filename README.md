# 📱 QRay - QR Kod Yönetim Uygulaması

<div align="center">

![QRay Logo](https://img.shields.io/badge/QRay-QR%20Code%20Manager-blue?style=for-the-badge&logo=qrcode)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Year](https://img.shields.io/badge/Year-2024-orange?style=for-the-badge)

**Modern, kullanıcı dostu QR kod tarama ve oluşturma uygulaması**

[Özellikler](#-özellikler) • [Kurulum](#-kurulum) • [Kullanım](#-kullanım) • [Teknolojiler](#-teknolojiler) • [Ekran Görüntüleri](#-ekran-görüntüleri)

</div>

---

## 📋 Hakkında

QRay, Flutter ile geliştirilmiş modern bir QR kod yönetim uygulamasıdır. QR kodları tarayabilir, oluşturabilir, özelleştirebilir ve bulut üzerinde senkronize edebilirsiniz. Supabase backend entegrasyonu ile verileriniz güvenli bir şekilde saklanır.

## ✨ Özellikler

### 🔍 QR Kod Tarama
- **Hızlı ve Hassas Tarama**: Mobile Scanner ile yüksek performanslı QR kod tarama
- **Otomatik İçerik Tanıma**: URL, vCard (kartvizit) ve metin içeriklerini otomatik algılama
- **Akıllı İşlemler**: 
  - URL'leri tarayıcıda açma
  - Kartvizit bilgilerini güzel bir arayüzle gösterme
  - Telefon numaralarını arama
  - E-posta gönderme
  - Web sitelerini açma
- **Kamera Kontrolleri**: Flaş açma/kapama, ön/arka kamera değiştirme

### 🎨 QR Kod Oluşturma
- **Özelleştirilebilir Tasarım**:
  - QR kod rengi seçimi
  - Arka plan rengi (transparan dahil)
  - Köşe kare rengi ve şekli
  - Veri modül şekli (kare/yuvarlak)
- **Hızlı Şablonlar**: Hazır renk şablonları ile hızlı oluşturma
- **Kartvizit QR**: vCard formatında kartvizit QR kodu oluşturma
- **Yüksek Kalite**: 512x512 piksel çözünürlükte QR kod üretimi

### 📚 Geçmiş ve Yönetim
- **QR Kod Geçmişi**: Tüm QR kodlarınızı görüntüleme
- **Kategorilendirme**: İçerik tipine göre otomatik kategorilendirme (URL, Kartvizit, Metin)
- **Arama ve Filtreleme**: İçerik bazlı arama
- **Toplu İşlemler**: 
  - Galeriye kaydetme (PNG)
  - Diğer uygulamalarla paylaşma
  - Silme işlemleri

### ☁️ Bulut Senkronizasyonu
- **Supabase Entegrasyonu**: Tüm QR kodlarınız bulutta güvenli şekilde saklanır
- **Çoklu Cihaz Desteği**: Farklı cihazlardan aynı verilere erişim
- **Otomatik Senkronizasyon**: Değişiklikler anında senkronize edilir

### 🎯 Kullanıcı Deneyimi
- **Modern UI/UX**: Material Design 3 ile modern arayüz
- **Açık/Koyu Tema**: Sistem temasına uyumlu otomatik tema geçişi
- **Türkçe Dil Desteği**: Tam Türkçe arayüz
- **Pull-to-Refresh**: Geçmiş listesini yenileme
- **Animasyonlar**: Akıcı geçiş animasyonları

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode
- Supabase hesabı

### Adımlar

1. **Projeyi klonlayın**
```bash
git clone https://github.com/mehmetcyr0/QRay.git
cd qray
```

2. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

3. **Supabase yapılandırması**
   - `lib/utils/constants.dart` dosyasını açın
   - Supabase URL ve anon key'inizi ekleyin:
   ```dart
   class Constants {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
     // ...
   }
   ```

4. **Supabase veritabanı kurulumu**
   - `supabase_schema.sql` dosyasındaki SQL komutlarını Supabase SQL Editor'de çalıştırın

5. **Uygulamayı çalıştırın**
```bash
flutter run
```

### Android Build
```bash
flutter build apk --release
```

### iOS Build
```bash
flutter build ios --release
```

## 📖 Kullanım

### QR Kod Tarama
1. Ana ekrandan "QR Kod Tara" butonuna tıklayın
2. Kamerayı QR koda doğrultun
3. Otomatik olarak taranır ve içerik gösterilir
4. URL ise tarayıcıda açılır, kartvizit ise güzel bir arayüzle gösterilir

### QR Kod Oluşturma
1. Ana ekrandan "QR Kod Oluştur" butonuna tıklayın
2. İçeriği girin (metin, URL, vb.)
3. "QR Kod Oluştur" butonuna tıklayın
4. Özelleştirme seçeneklerini kullanarak tasarımı değiştirin
5. "Kaydet" butonu ile kaydedin

### Kartvizit QR Kodu
1. Ana ekrandan "Kartvizit QR" butonuna tıklayın
2. Bilgilerinizi doldurun
3. QR kod otomatik oluşturulur
4. Kaydedin veya paylaşın

### Geçmiş Yönetimi
- Geçmiş ekranından tüm QR kodlarınızı görüntüleyin
- "Kaydet" ile galeriye kaydedin
- "Paylaş" ile diğer uygulamalarla paylaşın
- "Sil" ile silebilirsiniz

## 🛠️ Teknolojiler

### Frontend
- **Flutter** - Cross-platform framework
- **Dart** - Programlama dili
- **Provider** - State management
- **Material Design 3** - UI framework

### Backend & Database
- **Supabase** - Backend as a Service
  - Authentication
  - PostgreSQL Database
  - Real-time subscriptions

### Paketler
- `mobile_scanner` - QR kod tarama
- `qr_flutter` - QR kod oluşturma
- `supabase_flutter` - Supabase entegrasyonu
- `permission_handler` - İzin yönetimi
- `image_gallery_saver` - Galeriye kaydetme
- `share_plus` - Paylaşım
- `url_launcher` - URL açma
- `flutter_contacts` - Kişi yönetimi

## 📱 Ekran Görüntüleri

<!-- Ekran görüntüleri buraya eklenecek -->
<div align="center">

### Ana Ekran
![Ana Ekran](screenshots/home.png)

### QR Kod Tarama
![Tarama](screenshots/scanner.png)

### QR Kod Oluşturma
![Oluşturma](screenshots/create.png)

### Geçmiş
![Geçmiş](screenshots/history.png)

</div>

## 📁 Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── models/                   # Veri modelleri
│   └── qr_code_model.dart
├── screens/                  # Ekranlar
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── scanner_screen.dart
│   ├── create_qr_screen.dart
│   └── history_screen.dart
├── services/                 # Servisler
│   ├── auth_service.dart
│   ├── supabase_service.dart
│   └── qr_service.dart
├── widgets/                  # Widget'lar
│   └── qr_code_item.dart
├── utils/                    # Yardımcı dosyalar
│   ├── constants.dart
│   └── theme.dart
└── assets/                   # Varlıklar
    └── images/
```

## 🔐 Güvenlik

- Supabase Row Level Security (RLS) ile veri güvenliği
- Kullanıcı bazlı veri izolasyonu
- Güvenli kimlik doğrulama
- Hassas veriler şifrelenir

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen:

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Push edin (`git push origin feature/AmazingFeature`)
5. Pull Request açın

## 📝 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakın.

## 👨‍💻 Geliştirici

**Mehmet Çayır**

- GitHub: [@kullaniciadi](https://github.com/kullaniciadi)
- Email: mehmet@example.com

## 🙏 Teşekkürler

- Flutter ekibine harika framework için
- Supabase ekibine backend çözümü için
- Tüm açık kaynak paket geliştiricilerine

## 📊 İstatistikler

![GitHub stars](https://img.shields.io/github/stars/mehmetcyr0/QRay?style=social)
![GitHub forks](https://img.shields.io/github/forks/mehmetcyr0/QRay?style=social)
![GitHub issues](https://img.shields.io/github/issues/mehmetcyr0/QRay)
![GitHub pull requests](https://img.shields.io/github/issues-pr/mehmetcyr0/QRay)

---

<div align="center">

**⭐ Projeyi beğendiyseniz yıldız vermeyi unutmayın! ⭐**

Made with ❤️ in 2024

</div>
