/// App configuration for different environments
class AppConfig {
  // ============================================================
  // 🔧 CHANGE THIS URL AFTER DEPLOYING YOUR BACKEND
  // ============================================================
  // 
  // For local development: 'http://127.0.0.1:5000'
  // For production: 'https://your-backend-url.onrender.com'
  //
  static const String apiBaseUrl = 'https://carlog-api.onrender.com';
  
  // App info
  static const String appName = 'CarLog';
  static const String appVersion = '1.0.0';
  
  // Feature flags
  static const bool enableAnalytics = true;
  static const bool enableNotifications = false;
}

