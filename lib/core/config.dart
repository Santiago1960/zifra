import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get serverUrl => dotenv.env['SERVER_URL'] ?? 'http://127.0.0.1:8080';
}
