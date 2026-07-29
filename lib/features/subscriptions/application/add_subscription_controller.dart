import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/catalog/known_services.dart';
import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';
import 'subscription_providers.dart';

final addSubscriptionControllerProvider =
    StateNotifierProvider.autoDispose<
      AddSubscriptionController,
      AddSubscriptionState
    >((ref) {
      return AddSubscriptionController(
        ref.watch(subscriptionRepositoryProvider),
      );
    });

class AddSubscriptionState extends Equatable {
  AddSubscriptionState({
    this.serviceName = '',
    this.priceText = '',
    this.category = SubscriptionCategory.other,
    this.billingCycle = BillingCycle.monthly,
    DateTime? nextPaymentDate,
    this.selectedService,
    this.isSubmitting = false,
    this.errorMessage,
  }) : nextPaymentDate = nextPaymentDate ?? DateTime.now();

  final String serviceName;
  final String priceText;
  final SubscriptionCategory category;
  final BillingCycle billingCycle;
  final DateTime nextPaymentDate;
  final KnownService? selectedService;
  final bool isSubmitting;
  final String? errorMessage;

  List<KnownService> get suggestions =>
      KnownServices.suggestionsFor(serviceName);

  AddSubscriptionState copyWith({
    String? serviceName,
    String? priceText,
    SubscriptionCategory? category,
    BillingCycle? billingCycle,
    DateTime? nextPaymentDate,
    KnownService? selectedService,
    bool clearSelectedService = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddSubscriptionState(
      serviceName: serviceName ?? this.serviceName,
      priceText: priceText ?? this.priceText,
      category: category ?? this.category,
      billingCycle: billingCycle ?? this.billingCycle,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      selectedService: clearSelectedService
          ? null
          : selectedService ?? this.selectedService,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    serviceName,
    priceText,
    category,
    billingCycle,
    nextPaymentDate,
    selectedService,
    isSubmitting,
    errorMessage,
  ];
}

class AddSubscriptionController extends StateNotifier<AddSubscriptionState> {
  AddSubscriptionController(
    this._repository, {
    this._uuid = const Uuid(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(AddSubscriptionState());

  final SubscriptionRepository _repository;
  final Uuid _uuid;
  final DateTime Function() _clock;

  void setServiceName(String value) {
    final match = KnownServices.exactMatch(value);
    state = state.copyWith(
      serviceName: value,
      category: match?.category,
      selectedService: match,
      clearSelectedService: match == null,
      clearError: true,
    );
  }

  void selectService(KnownService service) {
    state = state.copyWith(
      serviceName: service.name,
      category: service.category,
      selectedService: service,
      clearError: true,
    );
  }

  void setPrice(String value) {
    state = state.copyWith(priceText: value, clearError: true);
  }

  void setCategory(SubscriptionCategory value) {
    state = state.copyWith(category: value, clearError: true);
  }

  void setBillingCycle(BillingCycle value) {
    state = state.copyWith(billingCycle: value, clearError: true);
  }

  void setNextPaymentDate(DateTime value) {
    state = state.copyWith(
      nextPaymentDate: DateTime(value.year, value.month, value.day),
      clearError: true,
    );
  }

  Future<bool> submit() async {
    final name = state.serviceName.trim();
    final priceInCents = _parsePriceInCents(state.priceText);
    if (name.isEmpty) {
      state = state.copyWith(errorMessage: 'Введите название сервиса');
      return false;
    }
    if (priceInCents == null || priceInCents <= 0) {
      state = state.copyWith(errorMessage: 'Укажите корректную стоимость');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    final now = _clock();
    final subscription = Subscription(
      id: _uuid.v4(),
      name: name,
      logo: state.selectedService?.logoKey,
      category: state.category,
      priceInCents: priceInCents,
      billingCycle: state.billingCycle,
      startDate: DateTime(now.year, now.month, now.day),
      nextPaymentDate: state.nextPaymentDate,
      status: SubscriptionStatus.active,
      totalSpentInCents: 0,
      reminderEnabled: true,
    );

    try {
      await _repository.createSubscription(subscription);
      state = state.copyWith(isSubmitting: false);
      return true;
    } on Object {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Не удалось сохранить подписку',
      );
      return false;
    }
  }

  static int? _parsePriceInCents(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[^\d,.]'), '')
        .replaceAll(',', '.');
    final amount = double.tryParse(normalized);
    if (amount == null || !amount.isFinite) return null;
    return (amount * 100).round();
  }
}
