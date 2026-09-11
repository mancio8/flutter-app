import 'package:flutter_starter/features/auth/presentation/pages/register_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../../features/users/presentation/pages/user_detail_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/ui_showcase_page.dart';
import '../../features/home/presentation/pages/skeleton_showcase_page.dart';
import '../../features/home/presentation/pages/error_showcase_page.dart';
import '../../features/home/presentation/pages/file_upload_showcase_page.dart';
import '../../features/home/presentation/pages/language_showcase_page.dart';
import '../../features/forms/presentation/pages/forms_example_page.dart';
import '../../features/rifornimenti/presentation/pages/rifornimenti_page.dart'; // NUOVO IMPORT
import '../../shared/widgets/responsive_scaffold.dart';
import '../../features/raccolta/presentation/pages/raccolta_page.dart';
import '../../features/biblioteca/presentation/pages/biblioteca_page.dart';
import '../../features/biblioteca/presentation/pages/wishlist_page.dart'; // NUOVO IMPORT
import '../../features/note/presentation/pages/note_page.dart';
import '../../features/habits/presentation/pages/habits_page.dart';
import '../../features/veicoli/presentation/pages/gestione_veicolo_page.dart'; // NUOVO IMPORT
import '../../features/veicoli/presentation/pages/veicoli_page.dart';
import '../../features/allenamenti/presentation/pages/allenamenti_page.dart';

final onboardingCompletedProvider = StateProvider<bool>((ref) {
  // This will be updated when onboarding is completed
  return false;
});

final _onboardingInitProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final completed = prefs.getBool('onboarding_completed') ?? false;

  // Update the state provider with the loaded value
  Future.microtask(() {
    ref.read(onboardingCompletedProvider.notifier).state = completed;
  });

  return completed;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);

  // Initialize onboarding state from preferences
  ref.watch(_onboardingInitProvider);

  return GoRouter(
    initialLocation: onboardingCompleted ? '/home' : '/onboarding',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      if (!onboardingCompleted && !isOnboardingRoute) {
        return '/onboarding';
      }

      // NUOVO: forza il login se non autenticato
      if (!isAuthenticated && !isAuthRoute && !isOnboardingRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => ResponsiveScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/rifornimenti', // NUOVA ROTTA
            builder: (context, state) => const RifornimentiPage(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersPage(),
            routes: [
              GoRoute(
                path: ':userId',
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  return UserDetailPage(userId: userId);
                },
              ),
            ],
          ),
          // Nella lista delle routes
          GoRoute(
            path: '/raccolta',
            builder: (context, state) => const RaccoltaPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/biblioteca',
            builder: (context, state) => const BibliotecaPage(),
          ),
          GoRoute(path: '/note', builder: (context, state) => const NotePage()),
          GoRoute(
            path: '/showcase/ui',
            builder: (context, state) => const UIShowcasePage(),
          ),
          GoRoute(
            path: '/showcase/skeletons',
            builder: (context, state) => const SkeletonShowcasePage(),
          ),
          GoRoute(
            path: '/showcase/errors',
            builder: (context, state) => const ErrorShowcasePage(),
          ),
          GoRoute(
            path: '/showcase/upload',
            builder: (context, state) => const FileUploadShowcasePage(),
          ),
          GoRoute(
            path: '/showcase/language',
            builder: (context, state) => const LanguageShowcasePage(),
          ),
          GoRoute(
            path: '/forms',
            builder: (context, state) => const FormsExamplePage(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsPage(),
          ),
          GoRoute(
            path: '/allenamenti',
            builder: (context, state) => const AllenamentiPage(),
          ),
          GoRoute(
            path: '/veicoli',
            builder: (context, state) => const VeicoliPage(),
          ),
          // Nel tuo file di routing
          GoRoute(
            path: '/wishlist',
            builder: (context, state) => const WishlistPage(),
          ),
          GoRoute(
            path: '/gestione-veicolo/:veicoloId',
            builder: (context, state) {
              final veicoloId = state.pathParameters['veicoloId']!;
              final nome = state.uri.queryParameters['nome'] ?? 'Veicolo';
              return GestioneVeicoloPage(
                veicoloId: veicoloId,
                nomeVeicolo: nome,
              );
            },
          ),
        ],
      ),
    ],
  );
});
