import 'dart:ui';
import 'dart:async';
import 'package:btc_trainer/services/background_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '/screens/home_screen.dart';
import '/viewmodels/wallet_viewmodel.dart';
import '/services/database_helper.dart';
import '/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  await initializeDateFormatting('pt_BR', null);

  // Check for DB updates on start
  await DatabaseHelper.instance.checkUpdateDB();

  await initializePricesService();

  runApp(const BtcTrainerApp());
}

Future<void> initializePricesService() async {
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

  PricesBackgroundService(service).init();
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
