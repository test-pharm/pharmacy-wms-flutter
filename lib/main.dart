import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/views/LoginView.dart';
import 'package:pharmacy_wms/Services/notificationService.dart';
import 'package:pharmacy_wms/Services/orderService.dart';
import 'package:pharmacy_wms/Services/OfflineService.dart';
import 'package:pharmacy_wms/Services/ConnectivityService.dart';
import 'package:pharmacy_wms/widgets/UpdateDialog.dart';

const String backgroundImagePath =    'assets/Gemini_Generated_Image_4jaq2t4jaq2t4jaq.png';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OfflineService.init();
  ConnectivityService().init();
  await AuthService.initialize();
  await initLanguage();
  await NotificationService.init();
  await OrderService.init();
  runApp(const PharmacyLoginApp());
}
class PharmacyLoginApp extends StatelessWidget {  const PharmacyLoginApp({super.key});  @override  Widget build(BuildContext context) {    return ValueListenableBuilder<ThemeMode>(      valueListenable: themeNotifier,      builder: (context, themeMode, _) {        return ValueListenableBuilder<AppLanguage>(          valueListenable: languageNotifier,          builder: (context, lang, _) {            final tr = AppLocalizations.of(lang);            return MaterialApp(              debugShowCheckedModeBanner: false,              title: tr.appTitle,              themeMode: themeMode,              theme: ThemeData(                useMaterial3: true,                brightness: Brightness.light,                scaffoldBackgroundColor: const Color(0xFFF2F7F8),                colorScheme: ColorScheme.fromSeed(                  seedColor: const Color(0xFF0A6B6E),                ),                fontFamily: lang == AppLanguage.ar ? 'Cairo' : null,              ),              darkTheme: ThemeData(                useMaterial3: true,                brightness: Brightness.dark,                scaffoldBackgroundColor: const Color(0xFF0E1418),                colorScheme: ColorScheme.fromSeed(                  seedColor: const Color(0xFF18B6B6),                  brightness: Brightness.dark,                ),                fontFamily: lang == AppLanguage.ar ? 'Cairo' : null,              ),              locale: lang == AppLanguage.ar                  ? const Locale('ar')                  : const Locale('en'),              supportedLocales: const [                Locale('en'),                Locale('ar'),              ],              localizationsDelegates: const [                GlobalMaterialLocalizations.delegate,                GlobalWidgetsLocalizations.delegate,                GlobalCupertinoLocalizations.delegate,              ],              home: UpdateCheckScope(                child: ProductProviderScope(child: const Loginview()),              ),            );          },        );      },    );  }}