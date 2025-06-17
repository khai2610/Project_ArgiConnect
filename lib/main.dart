import 'package:flutter/material.dart';

import 'app.dart'; // chứa MyApp
import 'config/session.dart';

void main() {
  // Không cần shared_preferences hoặc dotenv nếu không dùng .env
  runApp(const MyApp(initialRoute: '/login'));
}
