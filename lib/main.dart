import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'utils/constants.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/farmer/farmer_home_screen.dart';
import 'screens/provider/provider_home_screen.dart';
import 'screens/farmer/payment_success_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleInitialUri(); // Khi mở app từ deep link lúc khởi động
    _handleIncomingLinks(); // Khi app đang chạy và nhận link
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      _handleUri(uri);
    } catch (e) {
      debugPrint('❌ Error getInitialUri: $e');
    }
  }

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      _handleUri(uri);
    }, onError: (err) {
      debugPrint('❌ Deep link error (stream): $err');
    });
  }

  void _handleUri(Uri? uri) async {
    if (uri == null) return;
    debugPrint('📥 Deep link received: $uri');

    // Bắt link myapp://payment/success
    if (uri.scheme == 'myapp' &&
        uri.host == 'payment' &&
        uri.path == '/success') {
      final resultCode = uri.queryParameters['resultCode'];
      final invoiceId = uri.queryParameters['orderId']; // chính là _id

      if (resultCode == '0' && invoiceId != null) {
        try {
          // Cập nhật hóa đơn thành PAID
          final res = await http.patch(
            Uri.parse('$baseUrl/invoices/$invoiceId/mark-paid'),
            headers: {
              'Content-Type': 'application/json',
            },
          );

          if (res.statusCode == 200) {
            debugPrint('✅ Cập nhật hóa đơn thành PAID thành công');
          } else {
            debugPrint('❌ Cập nhật hóa đơn thất bại: ${res.body}');
          }
        } catch (e) {
          debugPrint('❌ Lỗi kết nối khi cập nhật hóa đơn: $e');
        }

        // Điều hướng sang PaymentSuccessScreen
        Future.delayed(Duration.zero, () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                onDone: () {
                  navigatorKey.currentState
                      ?.pop(); // Quay lại InvoiceDetailScreen
                },
              ),
            ),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Agri Drone App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/farmer-home': (_) => const FarmerHomeScreen(token: ''),
        '/provider-home': (_) => const ProviderHomeScreen(token: ''),
      },
    );
  }
}
