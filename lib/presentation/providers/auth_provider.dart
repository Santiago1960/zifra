import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zifra/domain/entities/user.dart';
import 'package:zifra/presentation/providers/dependency_injection.dart';

enum AuthStatus {
  initial,
  checking,
  unauthenticated,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final bool hasOpenProjects;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.hasOpenProjects = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? hasOpenProjects,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      hasOpenProjects: hasOpenProjects ?? this.hasOpenProjects,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Initialize state and trigger check
    // We can't make build async, so we start with initial state and trigger the check.
    // Ideally we use AsyncNotifier but Notifier is fine for this simple case if we handle loading state.
    // We'll trigger the check immediately after build (using a microtask or just calling it).
    // However, side effects in build are bad.
    // Better to call checkUser() from the UI or use FutureProvider for the initial check.
    // But to keep the logic here, we can schedule it.
    Future.microtask(() => checkUser());
    return AuthState();
  }

  Future<void> checkUser() async {
    // Avoid state update if already disposed or mounted check if needed
    state = state.copyWith(status: AuthStatus.checking);
    try {
      final userRepository = ref.read(userRepositoryProvider);
      final user = await userRepository.getUser();
      if (user != null) {
        // User found, check open projects
        final hasOpenProjects = await userRepository.hasOpenProjects(user.ruc);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          hasOpenProjects: hasOpenProjects,
        );
      } else {
        // User not found
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error);
    }
  }

  Future<void> registerUser(String name, String ruc) async {
    state = state.copyWith(status: AuthStatus.checking);
    try {
      final userRepository = ref.read(userRepositoryProvider);
      final user = User(name: name, ruc: ruc);
      await userRepository.saveUser(user);
      
      // After saving, check open projects
      final hasOpenProjects = await userRepository.hasOpenProjects(ruc);
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        hasOpenProjects: hasOpenProjects,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error);
    }
  }

  Future<void> logout() async {
    try {
      final userRepository = ref.read(userRepositoryProvider);
      await userRepository.deleteUser();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        hasOpenProjects: false,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
