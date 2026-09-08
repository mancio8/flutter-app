import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool clearUser = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription? _subscription;


  @override
  AuthState build() {
    final supabase = ref.watch(supabaseProvider);

    _subscription = supabase.auth.onAuthStateChange.listen((data) {
      state = state.copyWith(
        user: data.session?.user,
        clearUser: data.session == null,
      );
    });

    ref.onDispose(() => _subscription?.cancel());

    return AuthState(user: supabase.auth.currentUser);
  }

  Future<void> signIn(String email, String password) async {
    final supabase = ref.read(supabaseProvider);
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signUp(String email, String password) async {
    final supabase = ref.read(supabaseProvider);
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await supabase.auth.signUp(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    final supabase = ref.read(supabaseProvider);
    await supabase.auth.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});