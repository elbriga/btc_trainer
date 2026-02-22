import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
//import 'package:firebase_core/firebase_core.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';

import '/screens/home_screen.dart';
import '/viewmodels/wallet_viewmodel.dart';
import '/services/database_helper.dart';
import '/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  //await dotenv.load();
  //await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check for DB updates on start
  DatabaseHelper.instance.checkUpdateDB();

  runApp(const BtcTrainerApp());
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
