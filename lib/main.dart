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
      initialNotificationTitle: 'Serviço de Preço BTC',
      initialNotificationContent: 'Buscando o preço do Bitcoin...',
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
      return double.tryParse(data['USDBRL']['high']) ?? 0.00;
    } else {
      throw Exception('Falha ao carregar o preço do USD-BRL');
    }
  } catch (e) {
    throw Exception('Falha ao conectar ao servidor :: $e');
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
      throw Exception('Falha ao carregar o preço do BTC');
    }
  } catch (e) {
    throw Exception('Falha ao conectar ao servidor :: $e');
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
    final usdPrice = await fetchUsdBrlPrice();
    print(">>>>>>>>>>>>> USD price: " + usdPrice.toString());

    final price = await fetchBtcPrice();
    final priceData = PriceData(price: price, dollarPrice: usdPrice, timestamp: DateTime.now());
    await dbHelper.insertPrice(priceData);

    service.invoke('update', {
      "current_price": price,
      "dollar_price": usdPrice,
      "timestamp": priceData.timestamp.toIso8601String(),
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
        title: 'Simulador de BTC',
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
