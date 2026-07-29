import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../application/subscription_details_controller.dart';
import '../application/subscription_providers.dart';
import '../domain/entities/payment.dart';
import '../domain/entities/subscription.dart';
import '../domain/subscription_schedule.dart';
import 'subscription_ui_extensions.dart';
import 'widgets/service_logo.dart';

enum _DetailsAction { pause, resume, cancel, delete }

class SubscriptionDetailsScreen extends ConsumerWidget {
  const SubscriptionDetailsScreen({required this.subscriptionId, super.key});

  final String subscriptionId;

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
    _DetailsAction action,
  ) async {
    final controller = ref.read(
      subscriptionDetailsControllerProvider(subscriptionId).notifier,
    );

    if (action == _DetailsAction.delete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить подписку?'),
          content: Text(
            '${subscription.name} и история платежей будут удалены.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      final deleted = await controller.deleteSubscription();
      if (deleted && context.mounted) Navigator.pop(context);
      return;
    }

    final status = switch (action) {
      _DetailsAction.pause => SubscriptionStatus.paused,
      _DetailsAction.resume => SubscriptionStatus.active,
      _DetailsAction.cancel => SubscriptionStatus.cancelled,
      _DetailsAction.delete => subscription.status,
    };
    final updated = await controller.changeStatus(subscription, status);
    if (!updated && context.mounted) {
      _showError(context, 'Не удалось изменить статус');
    }
  }

  Future<void> _addPayment(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) async {
    final draft = await showModalBottomSheet<_PaymentDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPaymentSheet(subscription: subscription),
    );
    if (draft == null || !context.mounted) return;

    final saved = await ref
        .read(subscriptionDetailsControllerProvider(subscriptionId).notifier)
        .recordPayment(amountInCents: draft.amountInCents, date: draft.date);
    if (!saved && context.mounted) {
      _showError(context, 'Не удалось добавить платёж');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider(subscriptionId));
    final item = subscription.asData?.value;
    final actionState = ref.watch(
      subscriptionDetailsControllerProvider(subscriptionId),
    );

    return PopScope(
      canPop: !actionState.isLoading,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Подписка'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          actions: <Widget>[
            if (item != null)
              PopupMenuButton<_DetailsAction>(
                tooltip: 'Действия',
                onSelected: (action) {
                  unawaited(_handleAction(context, ref, item, action));
                },
                itemBuilder: (context) => <PopupMenuEntry<_DetailsAction>>[
                  if (item.status == SubscriptionStatus.paused)
                    const PopupMenuItem(
                      value: _DetailsAction.resume,
                      child: Text('Возобновить'),
                    )
                  else
                    const PopupMenuItem(
                      value: _DetailsAction.pause,
                      child: Text('Приостановить'),
                    ),
                  const PopupMenuItem(
                    value: _DetailsAction.cancel,
                    child: Text('Отменить подписку'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _DetailsAction.delete,
                    child: Text('Удалить'),
                  ),
                ],
              ),
          ],
        ),
        body: AppBackground(
          child: subscription.when(
            data: (value) {
              if (value == null) {
                return const EmptyState(
                  title: 'Подписка не найдена',
                  description: 'Возможно, она уже была удалена',
                  icon: Icons.search_off_rounded,
                );
              }
              return _DetailsContent(
                subscription: value,
                payments: ref.watch(paymentsProvider(subscriptionId)),
                isBusy: actionState.isLoading,
                onAddPayment: () {
                  unawaited(_addPayment(context, ref, value));
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const EmptyState(
              title: 'Не удалось открыть подписку',
              description: 'Попробуйте ещё раз',
              icon: Icons.error_outline_rounded,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.subscription,
    required this.payments,
    required this.isBusy,
    required this.onAddPayment,
  });

  final Subscription subscription;
  final AsyncValue<List<Payment>> payments;
  final bool isBusy;
  final VoidCallback onAddPayment;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          GlassCard(
            strong: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: <Widget>[
                Hero(
                  tag: 'subscription-logo-${subscription.id}',
                  child: ServiceLogo(
                    name: subscription.name,
                    logoKey: subscription.logo,
                    category: subscription.category,
                    size: 88,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  subscription.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: AppFormatters.money(subscription.priceInCents),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextSpan(
                        text: ' / ${subscription.billingCycle.shortLabel}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatusBadge(status: subscription.status),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  icon: Icons.event_rounded,
                  label: 'Следующий',
                  value: AppFormatters.shortDate(subscription.nextPaymentDate),
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  icon: Icons.category_rounded,
                  label: 'Категория',
                  value: subscription.category.label,
                  color: subscription.category.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricCard(
            icon: Icons.savings_rounded,
            label: 'Всего потрачено',
            value: AppFormatters.money(subscription.totalSpentInCents),
            color: AppColors.burgundy,
            horizontal: true,
          ),
          if (subscription.notes case final notes?
              when notes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Заметка',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(notes),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'История платежей',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: isBusy ? null : onAddPayment,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Добавить'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          payments.when(
            data: (items) => items.isEmpty
                ? const _EmptyPaymentHistory()
                : _PaymentHistory(payments: items),
            loading: () => const GlassCard(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) =>
                const GlassCard(child: Text('Не удалось загрузить историю')),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SubscriptionStatus.active => const Color(0xFF63C987),
      SubscriptionStatus.paused => AppColors.education,
      SubscriptionStatus.cancelled => AppColors.health,
      SubscriptionStatus.expired => AppColors.other,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        subscriptionStatusLabel(status),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

String subscriptionStatusLabel(SubscriptionStatus status) => status.label;

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.horizontal = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(this.icon, color: color, size: 21),
    );
    final text = Column(
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: horizontal
          ? Row(
              children: <Widget>[
                icon,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: text),
              ],
            )
          : Column(
              children: <Widget>[
                icon,
                const SizedBox(height: AppSpacing.sm),
                text,
              ],
            ),
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory({required this.payments});

  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: <Widget>[
          for (var index = 0; index < payments.length; index++) ...<Widget>[
            _PaymentRow(payment: payments[index]),
            if (index != payments.length - 1)
              Divider(color: Theme.of(context).dividerColor),
          ],
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.coral,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppFormatters.fullDate(payment.date),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            AppFormatters.money(payment.amountInCents),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _EmptyPaymentHistory extends StatelessWidget {
  const _EmptyPaymentHistory();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: <Widget>[
          const Icon(Icons.receipt_long_rounded, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Платежей пока нет',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Добавьте первый платёж вручную',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDraft {
  const _PaymentDraft({required this.amountInCents, required this.date});

  final int amountInCents;
  final DateTime date;
}

class _AddPaymentSheet extends StatefulWidget {
  const _AddPaymentSheet({required this.subscription});

  final Subscription subscription;

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  late final TextEditingController _amountController;
  late DateTime _date;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.subscription.priceInCents / 100).toStringAsFixed(
        widget.subscription.priceInCents % 100 == 0 ? 0 : 2,
      ),
    );
    final today = SubscriptionSchedule.dateOnly(DateTime.now());
    final nextPayment = SubscriptionSchedule.normalizedNextPayment(
      widget.subscription,
      today,
    );
    _date = today.isAfter(nextPayment) ? nextPayment : today;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final lastDate = SubscriptionSchedule.normalizedNextPayment(
      widget.subscription,
      DateTime.now(),
    );
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: lastDate,
      helpText: 'Дата платежа',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _submit() {
    final normalized = _amountController.text
        .replaceAll(RegExp(r'[^\d,.]'), '')
        .replaceAll(',', '.');
    final amount = double.tryParse(normalized);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Введите корректную сумму');
      return;
    }
    Navigator.pop(
      context,
      _PaymentDraft(amountInCents: (amount * 100).round(), date: _date),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Добавить платёж',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Сумма',
                  suffixText: '₽',
                  errorText: _error,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded),
                title: const Text('Дата платежа'),
                subtitle: Text(AppFormatters.fullDate(_date)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => unawaited(_pickDate()),
              ),
              const SizedBox(height: AppSpacing.md),
              GlassButton(
                label: 'Сохранить платёж',
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
