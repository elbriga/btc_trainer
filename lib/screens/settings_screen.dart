import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:btc_trainer/services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Conta')),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final dbPath = await getDatabasesPath();
                final path = join(dbPath, 'btc_trainer.db');
                SharePlus.instance.share(ShareParams(files: [XFile(path)]));
              },
              child: const Text('Download Database'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result == null || result.files.single.path == null) return;

                try {
                  await DatabaseHelper.instance.close();

                  final dbPath = await getDatabasesPath();
                  final dbFile = File(join(dbPath, 'btc_trainer.db'));
                  final backupFile =
                      File(join(dbPath, 'btc_trainer.db.bak'));

                  if (await dbFile.exists()) {
                    await dbFile.rename(backupFile.path);
                  }

                  await File(result.files.single.path!).copy(dbFile.path);

                  await DatabaseHelper.instance.database;

                  if (await backupFile.exists()) {
                    await backupFile.delete();
                  }

                  if (mounted) {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Database Restored'),
                        content: const Text(
                            'The database was successfully restored.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  final dbPath = await getDatabasesPath();
                  final dbFile = File(join(dbPath, 'btc_trainer.db'));
                  final backupFile =
                      File(join(dbPath, 'btc_trainer.db.bak'));

                  if (await backupFile.exists()) {
                    if (await dbFile.exists()) {
                      await dbFile.delete();
                    }
                    await backupFile.rename(dbFile.path);
                  }
                  await DatabaseHelper.instance.database;

                  if (mounted) {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Error restoring database'),
                        content: const Text(
                            'An error occurred during the restore process. The original database was restored.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('Restore Database'),
            ),
          ],
        ),
      ),
    );
  }
}
