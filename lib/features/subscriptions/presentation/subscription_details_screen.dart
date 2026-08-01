import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_accent_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/money_text.dart';
import '../../shell/presentation/hotbar_morph_sheet.dart';
import '../application/subscription_details_controller.dart';
import '../application/subscription_providers.dart';
import '../domain/entities/payment.dart';
import '../domain/entities/subscription.dart';
import '../domain/subscription_schedule.dart';
import 'subscription_ui_extensions.dart';
import 'widgets/service_logo.dart';

enum _StatusAction { pause, resume, cancel }

class SubscriptionDetailsScreen extends ConsumerWidget {
  const SubscriptionDetailsScreen({required this.subscriptionId, super.key});

  final String subscriptionId;

  Future<void> _handleStatusAction(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
    _StatusAction action,
  ) async {
    final controller = ref.read(
      subscriptionDetailsControllerProvider(subscriptionId).notifier,
    );

    if (action == _StatusAction.resume &&
        subscription.renewalMode == RenewalMode.manual) {
      final draft = await showHotbarMorphSheet<_PaymentDraft>(
        context: context,
        builder: (context) =>
            _AddPaymentSheet(subscription: subscription, isPlanning: true),
      );
      if (draft == null || !context.mounted) return;
      final planned = await controller.planManualPayment(
        subscription: subscription,
        amountInCents: draft.amountInCents,
        date: draft.date,
      );
      if (!planned && context.mounted) {
        _showError(context, 'Не удалось запланировать оплату');
      }
      return;
    }

    final status = switch (action) {
      _StatusAction.pause => SubscriptionStatus.paused,
      _StatusAction.resume => SubscriptionStatus.active,
      _StatusAction.cancel => SubscriptionStatus.cancelled,
    };
    final updated = await controller.changeStatus(subscription, status);
    if (!updated && context.mounted) {
      _showError(context, 'Не удалось изменить статус');
    }
  }

  Future<void> _deleteSubscription(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить подписку?'),
        content: Text('${subscription.name} и история платежей будут удалены.'),
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
    final deleted = await ref
        .read(subscriptionDetailsControllerProvider(subscriptionId).notifier)
        .deleteSubscription();
    if (deleted && context.mounted) Navigator.pop(context);
  }

  Future<void> _addPayment(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
  ) async {
    final draft = await showHotbarMorphSheet<_PaymentDraft>(
      context: context,
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
              IconButton(
                tooltip: 'Удалить подписку',
                onPressed: actionState.isLoading
                    ? null
                    : () => unawaited(_deleteSubscription(context, ref, item)),
                icon: const Icon(Icons.delete_outline_rounded),
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
                onStatusAction: (action) {
                  unawaited(_handleStatusAction(context, ref, value, action));
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
    required this.onStatusAction,
  });

  final Subscription subscription;
  final AsyncValue<List<Payment>> payments;
  final bool isBusy;
  final VoidCallback onAddPayment;
  final ValueChanged<_StatusAction> onStatusAction;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentTheme;
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
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    MoneyText(
                      cents: subscription.priceInCents,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      subscription.renewalMode == RenewalMode.manual
                          ? ' · единичная оплата'
                          : ' / ${subscription.billingCycle.periodLabel(customIntervalDays: subscription.customIntervalDays)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _StatusBadge(
                  status: subscription.status,
                  enabled: !isBusy,
                  onSelected: onStatusAction,
                ),
                if (subscription.renewalMode == RenewalMode.manual) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Без автоматического продления',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => context.pushNamed(
                          'edit-subscription',
                          pathParameters: <String, String>{
                            'id': subscription.id,
                          },
                        ),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Изменить'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  icon: Icons.event_rounded,
                  label: subscription.renewalMode == RenewalMode.manual
                      ? 'Запланировано'
                      : 'Следующий',
                  value: Text(
                    subscription.renewalMode == RenewalMode.manual &&
                            subscription.status != SubscriptionStatus.active
                        ? 'Нет активной оплаты'
                        : AppFormatters.shortDate(subscription.nextPaymentDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  color: accent.primary,
                  onTap: () => context.pushNamed(
                    'subscription-payment-schedule',
                    pathParameters: <String, String>{'id': subscription.id},
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  icon: Icons.category_rounded,
                  label: 'Категория',
                  value: Text(
                    subscription.category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  color: subscription.category.color(context),
                  onTap: () => context.goNamed(
                    'subscriptions',
                    queryParameters: <String, String>{
                      'category': subscription.category.name,
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricCard(
            icon: Icons.savings_rounded,
            label: 'Всего потрачено',
            value: MoneyText(
              cents: subscription.totalSpentInCents,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            color: accent.tertiary,
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
                onPressed:
                    isBusy ||
                        (subscription.renewalMode == RenewalMode.manual &&
                            subscription.status != SubscriptionStatus.active)
                    ? null
                    : onAddPayment,
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
  const _StatusBadge({
    required this.status,
    required this.enabled,
    required this.onSelected,
  });

  final SubscriptionStatus status;
  final bool enabled;
  final ValueChanged<_StatusAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.subberryTheme;
    final color = switch (status) {
      SubscriptionStatus.active => palette.success,
      SubscriptionStatus.paused => palette.warning,
      SubscriptionStatus.cancelled => palette.error,
      SubscriptionStatus.expired => palette.mutedTextColor,
    };

    return PopupMenuButton<_StatusAction>(
      enabled: enabled,
      tooltip: 'Изменить статус',
      onSelected: onSelected,
      itemBuilder: (context) => <PopupMenuEntry<_StatusAction>>[
        if (status == SubscriptionStatus.active)
          const PopupMenuItem(
            value: _StatusAction.pause,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.pause_circle_outline_rounded),
              title: Text('Приостановить'),
            ),
          )
        else
          const PopupMenuItem(
            value: _StatusAction.resume,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.play_circle_outline_rounded),
              title: Text('Возобновить'),
            ),
          ),
        if (status != SubscriptionStatus.cancelled)
          const PopupMenuItem(
            value: _StatusAction.cancel,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.block_rounded),
              title: Text('Отменить подписку'),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              subscriptionStatusLabel(status),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: color),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Icon(Icons.expand_more_rounded, size: 18, color: color),
          ],
        ),
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final Color color;
  final bool horizontal;
  final VoidCallback? onTap;

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
        value,
      ],
    );

    return GlassCard(
      onTap: onTap,
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
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppFormatters.fullDate(payment.date),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          MoneyText(
            cents: payment.amountInCents,
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
  const _AddPaymentSheet({required this.subscription, this.isPlanning = false});

  final Subscription subscription;
  final bool isPlanning;

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
    if (widget.isPlanning) {
      _date = today;
    } else {
      final nextPayment = SubscriptionSchedule.normalizedNextPayment(
        widget.subscription,
        today,
      );
      _date = today.isAfter(nextPayment) ? nextPayment : today;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final lastDate = widget.isPlanning
        ? DateTime.now().add(const Duration(days: 3650))
        : SubscriptionSchedule.normalizedNextPayment(
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
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
              widget.isPlanning ? 'Новая единичная оплата' : 'Добавить платёж',
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
              label: widget.isPlanning ? 'Запланировать' : 'Сохранить платёж',
              icon: Icons.check_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
