import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'core/database/sonic_database.dart';
import 'core/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize local SQLite database
  final database = await SonicDatabase.open();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const SonicApp(),
    ),
  );
}
