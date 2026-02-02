import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '/screens/home_screen.dart';
import '/viewmodels/wallet_viewmodel.dart';
import '/services/database_helper.dart';
import '/models/price_data.dart';
import '/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  // Check for DB updates on start
  DatabaseHelper.instance.checkUpdateDB();

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
  http.Response response;
  try {
    response = await http.get(
      Uri.parse('https://economia.awesomeapi.com.br/json/last/USD-BRL'),
    );
  } catch (e) {
    throw Exception('Falha ao conectar ao servidor :: $e');
  }

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return double.tryParse(data['USDBRL']['high']) ?? 0.00;
  } else {
    throw Exception('Falha ao carregar o preço do USD-BRL');
  }
}

Future<double> fetchBtcPrice() async {
  http.Response response;
  try {
    response = await http.get(
      Uri.parse(
        'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
      ),
    );
  } catch (e) {
    throw Exception('Falha ao conectar ao servidor :: $e');
  }

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['bitcoin']['usd'].toDouble();
  } else {
    throw Exception('Falha ao carregar o preço do BTC');
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
  double btcPrice = 0.0;
  double usdPrice = 0.0;

  void timerFunc(Timer? timer) async {
    double btc;
    try {
      btc = await fetchBtcPrice();
    } catch (e) {
      // print('Erro BTC: $e');
      if (btcPrice == 0.0) return; // Dont save if dont have value yet
      btc = btcPrice; // Use old value
    }
    btcPrice = btc;

    double usd;
    try {
      usd = await fetchUsdBrlPrice();
    } catch (e) {
      // print('Erro USD: $e');
      if (usdPrice == 0.0) return; // Dont save if dont have value yet
      usd = usdPrice; // Use old value
    }
    usdPrice = usd;

    final priceData = PriceData(
      price: btcPrice,
      dollarPrice: usdPrice,
      timestamp: DateTime.now(),
    );
    await dbHelper.insertPrice(priceData);

    service.invoke('update', {
      "btcPrice": btcPrice,
      "usdPrice": usdPrice,
      "timestamp": priceData.timestamp.toIso8601String(),
    });
    // print('=====>>>>>');
    // print('=====>>>>> New BTC $btcPrice');
    // print('=====>>>>>');
    // print('=====>>>>> New USD $usdPrice');
  }

  timerFunc(null);
  Timer.periodic(const Duration(minutes: 1), timerFunc);
}

class BtcTrainerApp extends StatelessWidget {
  const BtcTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WalletViewModel(),
      child: MaterialApp(
        title: 'Simulador de Bitcoin',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
