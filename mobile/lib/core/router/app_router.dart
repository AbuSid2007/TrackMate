import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/check_email_page.dart';
import '../../features/auth/presentation/pages/dashboard_placeholder_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String checkEmail = '/check-email';
  static const String dashboard = '/dashboard';

  static GoRouter create(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: _BlocListenable(authBloc),
      redirect: (context, state) {
        final authState = authBloc.state;
        final loc = state.matchedLocation;

        final isAuthRoute = loc == login || loc == register;
        final isCheckEmailRoute = loc == checkEmail;

        if (authState is AuthLoadingState || authState is AuthInitialState) {
          return null;
        }

        
        if (authState is AuthRegisteredState) {
          if (isCheckEmailRoute) return null;
          return '$checkEmail?email=${Uri.encodeComponent(authState.email)}';
        }

        if (authState is AuthUnverifiedState) {
          if (isCheckEmailRoute) return null;
          return '$checkEmail?email=${Uri.encodeComponent(authState.email)}';
        }

        if (authState is AuthVerificationSentState) {
          return isCheckEmailRoute ? null : checkEmail;
        }

        if (authState is AuthAuthenticatedState) {
          if (isAuthRoute || isCheckEmailRoute) return dashboard;
          return null;
        }

        if (authState is AuthUnauthenticatedState ||
            authState is AuthErrorState) {
          return isAuthRoute ? null : login;
        }
        
        return null;
      },
      routes: [
        GoRoute(path: splash, builder: (_, __) => const _SplashPage()),
        GoRoute(
          path: login,
          builder: (context, _) => LoginPage(
            onNavigateToRegister: () => context.go(register),
          ),
        ),
        GoRoute(
          path: register,
          builder: (context, _) => RegisterPage(
            onNavigateToLogin: () => context.go(login),
          ),
        ),
        // Change checkEmail route:
        GoRoute(
          path: checkEmail,
          builder: (context, state) => CheckEmailPage(
            email: state.uri.queryParameters['email'] ?? '',
          ),
        ),
        GoRoute(
          path: dashboard,
          builder: (_, __) => const DashboardPlaceholderPage(),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => LoginPage(
            onNavigateToRegister: () => context.go(register),
            verified: state.uri.queryParameters['verified'] == 'true',
          ),
        ),
      ],
    );
  }
}

class _BlocListenable extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _BlocListenable(AuthBloc bloc) {
    _sub = bloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2563EB),
      body: Center(
        child: Icon(
          Icons.track_changes_rounded,
          color: Colors.white,
          size: 56,
        ),
      ),
    );
  }
}