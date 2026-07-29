import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class UserProfileGateway {
  Future<String?> readName();

  Future<void> writeName(String name);
}

class SharedPreferencesUserProfileGateway implements UserProfileGateway {
  const SharedPreferencesUserProfileGateway();

  static const _nameKey = 'user_name';

  @override
  Future<String?> readName() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_nameKey);
  }

  @override
  Future<void> writeName(String name) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_nameKey, name);
  }
}

final userProfileGatewayProvider = Provider<UserProfileGateway>((ref) {
  return const SharedPreferencesUserProfileGateway();
});

final userProfileProvider =
    StateNotifierProvider<UserProfileController, UserProfileState>((ref) {
      return UserProfileController(ref.watch(userProfileGatewayProvider));
    });

class UserProfileState extends Equatable {
  const UserProfileState({
    this.name,
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  final String? name;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  UserProfileState copyWith({
    String? name,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UserProfileState(
      name: name ?? this.name,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[name, isLoading, isSaving, errorMessage];
}

class UserProfileController extends StateNotifier<UserProfileState> {
  UserProfileController(this._gateway) : super(const UserProfileState()) {
    unawaited(_restore());
  }

  final UserProfileGateway _gateway;

  Future<void> _restore() async {
    try {
      final storedName = (await _gateway.readName())?.trim();
      state = UserProfileState(
        name: storedName == null || storedName.isEmpty ? null : storedName,
        isLoading: false,
      );
    } on Object {
      state = const UserProfileState(isLoading: false);
    }
  }

  Future<bool> saveName(String value) async {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _gateway.writeName(normalized);
      state = UserProfileState(name: normalized, isLoading: false);
      return true;
    } on Object {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Не удалось сохранить имя',
      );
      return false;
    }
  }
}
