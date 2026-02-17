import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static String get emailAddress =>
      dotenv.env['EMAIL_ADDRESS'] ?? '';
  static String get emailAppPassword =>
      dotenv.env['EMAIL_APP_PASSWORD'] ?? '';
  // FCM v1 API (service account credentials)
  static String get fcmClientEmail =>
      dotenv.env['FCM_CLIENT_EMAIL'] ?? '';
  static String get fcmPrivateKey =>
      // .env stores \n as literal backslash-n — convert back to real newlines
      (dotenv.env['FCM_PRIVATE_KEY'] ?? '').replaceAll(r'\n', '\n');
  static String get fcmProjectId =>
      dotenv.env['FCM_PROJECT_ID'] ?? '';
  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'FreshBasket';
  static bool get isProduction =>
      (dotenv.env['APP_ENV'] ?? 'production') == 'production';
}
