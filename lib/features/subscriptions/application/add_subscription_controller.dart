import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/catalog/known_services.dart';
import '../domain/entities/payment.dart';
import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';
import '../domain/subscription_schedule.dart';
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

final editSubscriptionControllerProvider = StateNotifierProvider.autoDispose
    .family<AddSubscriptionController, AddSubscriptionState, String>((
      ref,
      subscriptionId,
    ) {
      final subscription = ref.watch(
        subscriptionProvider(
          subscriptionId,
        ).select((value) => value.asData?.value),
      );
      if (subscription == null) {
        throw StateError('Subscription $subscriptionId is not loaded.');
      }
      return AddSubscriptionController(
        ref.watch(subscriptionRepositoryProvider),
        initialSubscription: subscription,
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
    this.notesText = '',
    this.reminderEnabled = true,
    this.isSubmitting = false,
    this.errorMessage,
  }) : nextPaymentDate = nextPaymentDate ?? DateTime.now();

  final String serviceName;
  final String priceText;
  final SubscriptionCategory category;
  final BillingCycle billingCycle;
  final DateTime nextPaymentDate;
  final KnownService? selectedService;
  final String notesText;
  final bool reminderEnabled;
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
    String? notesText,
    bool? reminderEnabled,
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
      notesText: notesText ?? this.notesText,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
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
    notesText,
    reminderEnabled,
    isSubmitting,
    errorMessage,
  ];
}

class AddSubscriptionController extends StateNotifier<AddSubscriptionState> {
  AddSubscriptionController(
    this._repository, {
    this._uuid = const Uuid(),
    DateTime Function()? clock,
    Subscription? initialSubscription,
  }) : _clock = clock ?? DateTime.now,
       _initialSubscription = initialSubscription,
       super(
         initialSubscription == null
             ? AddSubscriptionState()
             : AddSubscriptionState(
                 serviceName: initialSubscription.name,
                 priceText: _formatPrice(initialSubscription.priceInCents),
                 category: initialSubscription.category,
                 billingCycle: initialSubscription.billingCycle,
                 nextPaymentDate: initialSubscription.nextPaymentDate,
                 selectedService: KnownServices.byLogoKey(
                   initialSubscription.logo,
                 ),
                 notesText: initialSubscription.notes ?? '',
                 reminderEnabled: initialSubscription.reminderEnabled,
               ),
       );

  final SubscriptionRepository _repository;
  final Uuid _uuid;
  final DateTime Function() _clock;
  final Subscription? _initialSubscription;

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

  void setNotes(String value) {
    state = state.copyWith(notesText: value, clearError: true);
  }

  void setReminderEnabled(bool value) {
    state = state.copyWith(reminderEnabled: value, clearError: true);
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
    final today = SubscriptionSchedule.dateOnly(now);
    final selectedPaymentDate = SubscriptionSchedule.dateOnly(
      state.nextPaymentDate,
    );
    final isOverdue = selectedPaymentDate.isBefore(today);
    final initial = _initialSubscription;
    var subscription = Subscription(
      id: initial?.id ?? _uuid.v4(),
      name: name,
      logo: state.selectedService?.logoKey,
      category: state.category,
      priceInCents: priceInCents,
      billingCycle: state.billingCycle,
      startDate:
          initial?.startDate ?? (isOverdue ? selectedPaymentDate : today),
      nextPaymentDate: selectedPaymentDate,
      billingAnchorDay: selectedPaymentDate.day,
      status: initial?.status ?? SubscriptionStatus.active,
      totalSpentInCents: initial?.totalSpentInCents ?? 0,
      reminderEnabled: state.reminderEnabled,
      notes: state.notesText.trim().isEmpty ? null : state.notesText.trim(),
    );
    if (isOverdue) {
      subscription = subscription.copyWith(
        nextPaymentDate: SubscriptionSchedule.normalizedNextPayment(
          subscription,
          today,
        ),
      );
    }

    try {
      if (initial == null) {
        await _repository.createSubscription(subscription);
      } else {
        await _repository.updateSubscription(subscription);
      }
      if (isOverdue) {
        await _repository.addPayment(
          Payment(
            id: _uuid.v4(),
            subscriptionId: subscription.id,
            amountInCents: priceInCents,
            date: selectedPaymentDate,
          ),
        );
      }
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

  static String _formatPrice(int priceInCents) {
    final amount = priceInCents / 100;
    return amount.toStringAsFixed(priceInCents % 100 == 0 ? 0 : 2);
  }
}
