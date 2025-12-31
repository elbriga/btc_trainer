import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import 'screens/home_screen.dart';
import 'viewmodels/wallet_viewmodel.dart';
import 'services/database_helper.dart';
import 'models/price_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  await initializeService();
  runApp(const BtcTrainerApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'btc_trainer_service',
      initialNotificationTitle: 'BTC Price Service',
      initialNotificationContent: 'Fetching Bitcoin price...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

Future<double> fetchUsdBrlPrice() async {
  try {
    final response = await http.get(
      Uri.parse('https://economia.awesomeapi.com.br/json/last/USD-BRL'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['USDBRL']['high'].toDouble();
    } else {
      throw Exception('Failed to load USD-BRL price');
    }
  } catch (e) {
    throw Exception('Failed to connect to the server');
  }
}

Future<double> fetchBtcPrice() async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['bitcoin']['usd'].toDouble();
    } else {
      throw Exception('Failed to load BTC price');
    }
  } catch (e) {
    throw Exception('Failed to connect to the server');
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final dbHelper = DatabaseHelper.instance;

  Timer.periodic(const Duration(minutes: 1), (timer) async {
    final btcPrice = await fetchBtcPrice();
    final usdPrice = await fetchUsdBrlPrice();

    final btcPriceData = PriceData(
      btcPrice: btcPrice,
      usdPrice: usdPrice,
      timestamp: DateTime.now(),
    );

    await dbHelper.insertPrice(btcPriceData);

    service.invoke('update', {
      "current_price": btcPrice,
      "timestamp": btcPriceData.timestamp.toIso8601String(),
    });
  });
}

class BtcTrainerApp extends StatelessWidget {
  const BtcTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WalletViewModel(),
      child: MaterialApp(
        title: 'BTC Trainer',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
