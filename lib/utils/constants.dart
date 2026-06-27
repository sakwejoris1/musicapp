class AppConstants {
  static const baseUrl = 'http://localhost:3000/api';
  static const wsUrl = 'ws://localhost:3000';

  // Price limits
  static const songPriceMin = 50;
  static const songPriceMax = 100;
  static const albumPriceMin = 500;
  static const albumPriceMax = 3000;
  static const subscriptionDaily = 150;
  static const subscriptionMonthly = 3000;
  static const offlineListeningPrice = 100;
  static const minListensBeforeStream = 20;
  static const listenPackagePrice = 50;
  static const supportMin = 1;
  static const supportMax = 10000;

  // Currencies
  static const currencies = ['FCFA', 'NGN', 'XAF', 'USD'];

  // Payment methods
  static const paymentOrange = 'orange_money';
  static const paymentMTN = 'mtn_momo';
  static const paymentNeero = 'neero';

  // Content types
  static const contentAudio = 'audio';
  static const contentVideo = 'video';
  static const contentAlbum = 'album';

  // Genres
  static const genres = [
    'Afrobeat', 'Bikutsi', 'Makossa', 'Ndombolo', 'Coupé-Décalé',
    'Afropop', 'Gospel', 'Hip-Hop', 'R&B', 'Jazz', 'Reggae',
    'Zouk', 'Highlife', 'Fuji', 'Jùjú', 'Other'
  ];

  // Product categories
  static const categories = [
    'clothing', 'accessories', 'merchandise', 'digital', 'other'
  ];

  // Storage keys
  static const keyToken = 'auth_token';
  static const keyUser = 'current_user';
  static const keyLanguage = 'app_language';
  static const keyPurchases = 'purchases';
  static const keyOfflineQueue = 'offline_queue';
}
