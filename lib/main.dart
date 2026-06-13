import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/router/router.dart';
import 'package:tantin_flutter/core/theme/theme.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/notifications/data/notification_providers.dart';
import 'package:tantin_flutter/firebase_options.dart';
import 'package:tantin_flutter/l10n/app_localizations.dart';

/// Background message handler. Must be a top-level function annotated with
/// `@pragma('vm:entry-point')` so it survives tree-shaking and runs in its own
/// isolate. FCM `notification` messages are surfaced by the system tray
/// automatically while the app is backgrounded, so there is nothing to do here
/// yet — the hook exists for future data-only handling.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Debug builds use the App Check debug provider with a FIXED debug token so
  // we don't have to scrape it from logcat. This token is dev-only and grants
  // nothing on its own — it must be registered in Firebase Console → App Check
  // → Manage debug tokens, and Firestore rules still apply. Release builds use
  // Play Integrity (the default provider fails on dev devices with
  // "Too many attempts", blocking the App Check-enforced callables).
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider(
            debugToken: 'a8303487-876e-41be-8a07-8e971edc9229',
          )
        : const AndroidPlayIntegrityProvider(),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
    );
    return true;
  };

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  await FirebaseAnalytics.instance.logAppOpen();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenSub;
  String? _registeredUid;

  @override
  void initState() {
    super.initState();
    unawaited(_setupMessaging());
  }

  /// Wires push-notification tap routing and token-refresh persistence. The
  /// whole body is guarded: in a test environment (no Firebase app, mocked
  /// channels) every messaging call throws, and we simply skip setup rather
  /// than crash the boot.
  Future<void> _setupMessaging() async {
    try {
      final push = ref.read(pushMessagingProvider);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _routeFromMessage(initial);
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(
        _routeFromMessage,
        onError: (Object _) {},
      );
      _tokenSub = push.onTokenRefresh.listen(
        (token) {
          final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
          if (uid != null) unawaited(push.saveToken(uid, token));
        },
        onError: (Object _) {},
      );
    } on Object catch (error) {
      debugPrint('Push messaging setup skipped: $error');
    }
  }

  void _routeFromMessage(RemoteMessage message) {
    final daretId = message.data['daretId'];
    if (daretId is String && daretId.isNotEmpty) {
      unawaited(ref.read(routerProvider).push<void>('/daret/$daretId'));
    }
  }

  /// Registers the device token once the user is authenticated AND has a
  /// profile, so the write satisfies the security rules (a user doc exists).
  void _maybeRegisterToken() {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (uid == null || profile == null || !profile.exists) return;
    if (_registeredUid == uid) return;
    _registeredUid = uid;
    unawaited(ref.read(pushMessagingProvider).registerForUser(uid));
  }

  @override
  void dispose() {
    unawaited(_openedSub?.cancel());
    unawaited(_tokenSub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(authStateChangesProvider, (_, _) => _maybeRegisterToken())
      ..listen(userProfileProvider, (_, _) => _maybeRegisterToken());
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: "Tant'in",
      theme: TantinTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''),
      ],
      routerConfig: goRouter,
    );
  }
}
