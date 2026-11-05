import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.hasCompletedOnboarding = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  final UserModel? user;
  final bool isLoading;
  final bool hasCompletedOnboarding;
  final String? errorMessage;
  final bool isInitialized;

  bool get isAuthenticated => user != null;
  bool get isEmailVerified => user?.isEmailVerified ?? false;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? hasCompletedOnboarding,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState()) {
    initialize();
  }

  final AuthRepository _repository;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool('has_completed_onboarding') ?? false;
    final currentUser = await _repository.getCurrentUser();

    state = state.copyWith(
      user: currentUser,
      hasCompletedOnboarding: hasOnboarded,
      isLoading: false,
      isInitialized: true,
    );
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signUp(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
      return false;
    }
  }

  Future<bool> updateProfile({String? name, String? photoUrl}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await _repository.updateProfile(name: name, photoUrl: photoUrl);
      state = state.copyWith(user: updatedUser, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
      return false;
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final isVerified = await _repository.checkEmailVerified();
      if (isVerified && state.user != null) {
        state = state.copyWith(
          user: state.user!.copyWith(isEmailVerified: true),
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    try {
      await _repository.sendEmailVerification();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _formatError(e));
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.sendPasswordReset(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _formatError(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = state.copyWith(clearUser: true);
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    state = state.copyWith(clearUser: true);
  }

  String _formatError(Object error) {
    final msg = error.toString();
    if (msg.contains('user-not-found')) return 'No user found for this email address.';
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('email-already-in-use')) {
      return 'This email address is already registered.';
    }
    if (msg.contains('weak-password')) return 'Password is too weak.';
    if (msg.contains('invalid-email')) return 'Please enter a valid email address.';
    if (msg.contains('network-request-failed')) return 'Network error. Please check your connection.';
    return msg.replaceFirst('Exception: ', '');
  }
}
