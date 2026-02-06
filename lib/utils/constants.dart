class Constants {
  // Supabase Bağlantı Bilgileri
  static const String supabaseUrl = 'https://fhkkuusiyhwgpjetevbj.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_I4H3-G79uUJPVUfAfdy5vQ_-glt2RWZ';

  // Veritabanı Tabloları
  static const String qrCodesTable = 'qr_codes';

  // Hata Mesajları
  static const String errorAuth = 'Kimlik doğrulama başarısız';
  static const String errorNetwork = 'İnternet bağlantısı yok';
  static const String errorUnexpected = 'Beklenmeyen bir hata meydana geldi';
  static const String errorInvalidCredentials = 'E-posta veya şifre yanlış';
  static const String errorEmailNotConfirmed = 'E-posta adresinizi doğrulayın';
  static const String errorUserExists = 'Bu e-posta adresi zaten kullanılıyor';
  static const String errorWeakPassword = 'Şifre en az 6 karakter olmalıdır';

  // Başarı Mesajları
  static const String successLogin = 'Başarıyla giriş yaptınız!';
  static const String successRegister =
      'Kayıt tamamlandı! E-posta adresinizi doğrulayın.';
  static const String successLogout = 'Çıkış işlemi başarılı!';
  static const String successQrScan = 'QR kod başarıyla tarandı!';
  static const String successQrSave = 'QR kod başarıyla kaydedildi!';
  static const String successQrDelete = 'QR kod başarıyla silindi!';

  // Rotalar
  static const String splashRoute = '/';
  static const String loginRoute = '/giris';
  static const String registerRoute = '/kayit';
  static const String homeRoute = '/anasayfa';
  static const String historyRoute = '/gecmis';
  static const String scannerRoute = '/tarayici';

  // Genel Mesajlar
  static const String errorGeneric = 'Bir hata oluştu. Lütfen tekrar deneyin.';
  static const String successQrGenerated = 'QR kod başarıyla oluşturuldu!';
  static const String qrBelongsToYou = 'Bu QR kod zaten size ait!';
}
