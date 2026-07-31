import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../application/add_subscription_controller.dart';
import '../application/subscription_providers.dart';
import '../data/catalog/known_services.dart';
import '../domain/entities/subscription.dart';
import 'subscription_ui_extensions.dart';
import 'widgets/service_logo.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  const AddSubscriptionScreen({this.subscriptionId, super.key});

  final String? subscriptionId;

  @override
  ConsumerState<AddSubscriptionScreen> createState() =>
      _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends ConsumerState<AddSubscriptionScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _customDaysController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _initializedControllers = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _customDaysController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _selectService(KnownService service) {
    _controller().selectService(service);
    _nameController
      ..text = service.name
      ..selection = TextSelection.collapsed(offset: service.name.length);
    _nameFocusNode.unfocus();
  }

  Future<void> _pickDate(DateTime selectedDate) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      helpText: 'Следующее списание',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );
    if (date == null) return;
    _controller().setNextPaymentDate(date);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final saved = await _controller().submit();
    if (!mounted || !saved) return;
    Navigator.of(context).pop(true);
  }

  AddSubscriptionController _controller() {
    final subscriptionId = widget.subscriptionId;
    return subscriptionId == null
        ? ref.read(addSubscriptionControllerProvider.notifier)
        : ref.read(editSubscriptionControllerProvider(subscriptionId).notifier);
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionId = widget.subscriptionId;
    if (subscriptionId != null &&
        ref.watch(subscriptionProvider(subscriptionId)).asData?.value == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(child: Center(child: CircularProgressIndicator())),
      );
    }
    final state = subscriptionId == null
        ? ref.watch(addSubscriptionControllerProvider)
        : ref.watch(editSubscriptionControllerProvider(subscriptionId));
    final controller = _controller();
    if (!_initializedControllers) {
      _initializedControllers = true;
      _nameController.text = state.serviceName;
      _priceController.text = state.priceText;
      _notesController.text = state.notesText;
      _customDaysController.text = '${state.customIntervalDays}';
    }
    final selectedService = state.selectedService;

    return PopScope(
      canPop: !state.isSubmitting,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            subscriptionId == null ? 'Новая подписка' : 'Изменить подписку',
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: AppBackground(
          child: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
              ),
              children: <Widget>[
                _ServicePreview(
                  name: state.serviceName,
                  selectedService: selectedService,
                  category: state.category,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(
                  title: 'Сервис',
                  caption: 'Найдём логотип и категорию автоматически',
                ),
                const SizedBox(height: AppSpacing.sm),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.name],
                        onChanged: controller.setServiceName,
                        decoration: const InputDecoration(
                          labelText: 'Название',
                          hintText: 'Например, Netflix',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child:
                            state.suggestions.isEmpty || selectedService != null
                            ? const SizedBox.shrink()
                            : Padding(
                                key: ValueKey<String>(state.serviceName),
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Column(
                                  children: <Widget>[
                                    for (final service in state.suggestions)
                                      _ServiceSuggestion(
                                        service: service,
                                        onTap: () => _selectService(service),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel(
                  title: 'Тип оплаты',
                  caption: 'Автопродление или одна оплата по вашему решению',
                ),
                const SizedBox(height: AppSpacing.sm),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<RenewalMode>(
                      segments: const <ButtonSegment<RenewalMode>>[
                        ButtonSegment(
                          value: RenewalMode.automatic,
                          label: Text('Автоматическая'),
                          icon: Icon(Icons.autorenew_rounded),
                        ),
                        ButtonSegment(
                          value: RenewalMode.manual,
                          label: Text('Единичная'),
                          icon: Icon(Icons.looks_one_rounded),
                        ),
                      ],
                      selected: <RenewalMode>{state.renewalMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        controller.setRenewalMode(selection.first);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(
                  title: state.renewalMode == RenewalMode.manual
                      ? 'Ожидаемая стоимость'
                      : 'Стоимость и период',
                ),
                const SizedBox(height: AppSpacing.sm),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: controller.setPrice,
                        decoration: InputDecoration(
                          labelText: state.renewalMode == RenewalMode.manual
                              ? 'Стоимость этой оплаты'
                              : 'Стоимость',
                          hintText: '799',
                          prefixIcon: const Icon(Icons.payments_rounded),
                          suffixText: '₽',
                        ),
                      ),
                      if (state.renewalMode ==
                          RenewalMode.automatic) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: AppSpacing.xs,
                          crossAxisSpacing: AppSpacing.xs,
                          childAspectRatio: 3.4,
                          children: <Widget>[
                            for (final cycle in const <BillingCycle>[
                              BillingCycle.monthly,
                              BillingCycle.quarterly,
                              BillingCycle.semiannual,
                              BillingCycle.yearly,
                              BillingCycle.biennial,
                              BillingCycle.custom,
                            ])
                              ChoiceChip(
                                showCheckmark: false,
                                labelPadding: EdgeInsets.zero,
                                label: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    cycle.label,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                selected: state.billingCycle == cycle,
                                selectedColor: AppColors.coral.withValues(
                                  alpha: 0.28,
                                ),
                                onSelected: (_) =>
                                    controller.setBillingCycle(cycle),
                              ),
                          ],
                        ),
                        if (state.billingCycle ==
                            BillingCycle.custom) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            keyboardType: TextInputType.number,
                            controller: _customDaysController,
                            onChanged: (value) {
                              final days = int.tryParse(value.trim());
                              if (days != null) {
                                controller.setCustomIntervalDays(days);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Период в днях',
                              hintText: '30',
                              prefixIcon: Icon(Icons.timelapse_rounded),
                              suffixText: 'дн.',
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel(
                  title: 'Категория',
                  caption: 'Можно изменить предложенный вариант',
                ),
                const SizedBox(height: AppSpacing.sm),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      for (final category in SubscriptionCategory.values)
                        ChoiceChip(
                          showCheckmark: false,
                          label: Text('${category.emoji} ${category.label}'),
                          selected: state.category == category,
                          selectedColor: category.color.withValues(alpha: 0.28),
                          side: BorderSide(
                            color: state.category == category
                                ? category.color
                                : Theme.of(context).dividerColor,
                          ),
                          onSelected: (_) => controller.setCategory(category),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(
                  title: state.renewalMode == RenewalMode.manual
                      ? 'Планируемая оплата'
                      : 'Следующее списание',
                  caption: state.renewalMode == RenewalMode.manual
                      ? 'После оплаты автопродления не будет'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                GlassCard(
                  padding: EdgeInsets.zero,
                  onTap: () => unawaited(_pickDate(state.nextPaymentDate)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.coral.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.coral,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                state.renewalMode == RenewalMode.manual
                                    ? 'Дата единичной оплаты'
                                    : 'Дата платежа',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'd MMMM yyyy',
                                  'ru',
                                ).format(state.nextPaymentDate),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel(
                  title: 'Дополнительно',
                  caption: 'Напоминания и заметка',
                ),
                const SizedBox(height: AppSpacing.sm),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.notifications_rounded),
                        title: const Text('Напоминать о списании'),
                        value: state.reminderEnabled,
                        onChanged: controller.setReminderEnabled,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _notesController,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: controller.setNotes,
                        decoration: const InputDecoration(
                          labelText: 'Заметка',
                          hintText: 'Необязательно',
                          prefixIcon: Icon(Icons.notes_rounded),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: state.errorMessage == null
                      ? const SizedBox(height: AppSpacing.lg)
                      : Padding(
                          key: ValueKey<String>(state.errorMessage!),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                ),
                GlassButton(
                  label: state.isSubmitting
                      ? 'Сохраняем...'
                      : subscriptionId == null
                      ? 'Добавить подписку'
                      : 'Сохранить изменения',
                  icon: state.isSubmitting
                      ? null
                      : subscriptionId == null
                      ? Icons.add_rounded
                      : Icons.check_rounded,
                  onPressed: state.isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServicePreview extends StatelessWidget {
  const _ServicePreview({
    required this.name,
    required this.selectedService,
    required this.category,
  });

  final String name;
  final KnownService? selectedService;
  final SubscriptionCategory category;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Новый сервис' : name.trim();

    return GlassCard(
      strong: true,
      child: Row(
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: ServiceLogo(
              key: ValueKey<String?>(selectedService?.logoKey ?? displayName),
              name: displayName,
              logoKey: selectedService?.logoKey,
              category: category,
              size: 68,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    displayName,
                    key: ValueKey<String>(displayName),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${category.emoji} ${category.label}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (selectedService != null)
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.coral,
              size: 22,
            ),
        ],
      ),
    );
  }
}

class _ServiceSuggestion extends StatelessWidget {
  const _ServiceSuggestion({required this.service, required this.onTap});

  final KnownService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      leading: ServiceLogo(
        name: service.name,
        logoKey: service.logoKey,
        category: service.category,
        size: 42,
      ),
      title: Text(service.name),
      subtitle: Text('${service.category.emoji} ${service.category.label}'),
      trailing: const Icon(Icons.north_west_rounded, size: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      onTap: onTap,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (caption case final caption?) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              caption,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
