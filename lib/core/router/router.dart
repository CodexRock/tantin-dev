import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/design_system/gallery/gallery_screen.dart';
import 'package:tantin_flutter/features/activity/presentation/screens/activite_screen.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/calendar/presentation/screens/calendrier_screen.dart';
import 'package:tantin_flutter/features/darets/presentation/screens/daret_hub_stub_screen.dart';
import 'package:tantin_flutter/features/darets/presentation/screens/mes_darets_screen.dart';
import 'package:tantin_flutter/features/dashboard/presentation/screens/home_screen.dart';
import 'package:tantin_flutter/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/contacts_screen.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/intro_screen.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/otp_screen.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/phone_screen.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:tantin_flutter/features/profile/presentation/screens/profil_screen.dart';
import 'package:tantin_flutter/features/shell/presentation/create_join_sheet.dart';

part 'router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRoutes {
  static const splash = '/';
  static const intro = '/intro';
  static const phone = '/phone';
  static const otp = '/otp';
  static const profileSetup = '/profile-setup';
  static const contacts = '/contacts';
  static const home = '/home';
  static const darets = '/darets';
  static const calendar = '/calendar';
  static const activity = '/activity';
  static const profile = '/profile';
  static const gallery = '/gallery';
  static const notifications = '/notifications';
}

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref
      ..listen(
        authStateChangesProvider,
        (previous, next) => notifyListeners(),
      )
      ..listen(
        userProfileProvider,
        (previous, next) => notifyListeners(),
      );
  }
}

@riverpod
GoRouter router(Ref ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final userProfile = ref.read(userProfileProvider);

      if (authState.isLoading || userProfile.isLoading) return null;

      final user = authState.value;
      final profile = userProfile.value;

      final isAuthRoute = [
        AppRoutes.splash,
        AppRoutes.intro,
        AppRoutes.phone,
        AppRoutes.otp,
      ].contains(state.uri.path);

      final isProfileSetup = state.uri.path == AppRoutes.profileSetup;
      final isContacts = state.uri.path == AppRoutes.contacts;

      if (user == null) {
        if (!isAuthRoute) return AppRoutes.splash;
        return null;
      }

      if (profile != null) {
        if (!profile.exists) {
          if (!isProfileSetup && !isContacts) return AppRoutes.profileSetup;
          return null;
        } else {
          if (isAuthRoute || isProfileSetup || isContacts) {
            return AppRoutes.home;
          }
          return null;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.intro,
        builder: (context, state) => const IntroScreen(),
      ),
      GoRoute(
        path: AppRoutes.phone,
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.contacts,
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: AppRoutes.gallery,
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: '/daret/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            DaretHubStubScreen(daretId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            floatingActionButton: FloatingActionButton(
              onPressed: () => showCreateJoinSheet(context),
              backgroundColor: TantinColors.saffron,
              elevation: 4,
              child: TnIcons.plus(size: 28, color: TantinColors.ink),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group),
                  label: 'Mes Darets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: 'Calendrier',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Activité',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.darets,
                builder: (context, state) => const MesDaretsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                builder: (context, state) => const CalendrierScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.activity,
                builder: (context, state) => const ActiviteScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
