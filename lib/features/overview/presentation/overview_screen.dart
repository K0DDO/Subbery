import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_accent_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_header.dart';
import '../../analytics/presentation/widgets/spending_detail_sheet.dart';
import '../../profile/application/user_profile_controller.dart';
import '../../shell/application/tab_reset_provider.dart';
import '../../subscriptions/application/subscription_providers.dart';
import '../../subscriptions/domain/entities/payment.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/presentation/subscription_visuals.dart';
import '../../subscriptions/presentation/widgets/glass_payment_row.dart';
import '../../subscriptions/presentation/widgets/service_logo.dart';
import '../application/overview_metrics.dart';
import 'widgets/berry_calendar_ring.dart';
import 'widgets/spending_bar_chart.dart';

@visibleForTesting
bool isAdminDateSimulator(String? name) {
  return name?.trim().toLowerCase() == 'dima4ka';
}

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  int _selectedMonth = DateTime.now().month;
  int _ringPage = 0;
  int _debugDayOffset = 0;

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final payments = ref.watch(allPaymentsProvider);
    final resetRevision = ref.watch(tabResetRevisionProvider(0));
    final userName = ref.watch(
      userProfileProvider.select((profile) => profile.name),
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          ScreenHeader(
            title: 'Привет, ${userName ?? ''} 👋',
            subtitle: 'Ваши подписки под контролем',
          ),
          Expanded(
            child: subscriptions.when(
              data: (items) => payments.when(
                data: (paymentItems) =>
                    _buildContent(items, paymentItems, resetRevision, userName),
                loading: _LoadingOverview.new,
                error: (error, stackTrace) => const _OverviewError(),
              ),
              loading: _LoadingOverview.new,
              error: (error, stackTrace) => const _OverviewError(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<Subscription> subscriptions,
    List<Payment> payments,
    int resetRevision,
    String? userName,
  ) {
    if (subscriptions.isEmpty) {
      return EmptyState(
        title: 'Пока нет подписок 🍓',
        description:
            'Добавьте первый сервис,\n'
            'чтобы начать контролировать расходы',
        actionLabel: 'Добавить подписку',
        onAction: () => context.push('/subscriptions/add'),
      );
    }

    final realNow = DateTime.now();
    final now = DateTime(
      realNow.year,
      realNow.month,
      realNow.day,
    ).add(Duration(days: _debugDayOffset));
    final metrics = OverviewMetrics.calculate(
      subscriptions: subscriptions,
      payments: payments,
      now: now,
    );
    final visibleRingOccurrences = _ringPage == 0
        ? metrics.upcomingPayments
        : metrics.yearOccurrences;
    final selectedOccurrences = visibleRingOccurrences
        .where(
          (occurrence) =>
              occurrence.date.month == _selectedMonth &&
              occurrence.date.year == now.year,
        )
        .toList(growable: false);

    return ListView(
      key: ValueKey<String>('overview-$resetRevision'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        128,
      ),
      children: <Widget>[
        _MonthlySummary(metrics: metrics),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          strong: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 392,
                child: PageView(
                  onPageChanged: (page) {
                    setState(() => _ringPage = page);
                  },
                  children: <Widget>[
                    _RingGalleryPage(
                      title: 'Ближайшие платежи',
                      subtitle: '',
                      year: now.year,
                      now: now,
                      occurrences: metrics.upcomingPayments,
                      periodArcOccurrences: metrics.upcomingPayments,
                      counterValue: metrics.dueThisMonthCount,
                      selectedMonth: _selectedMonth,
                      showPeriodArcs: true,
                      showCalendarLogos: false,
                      onMonthSelected: (month) {
                        setState(() => _selectedMonth = month);
                      },
                    ),
                    _RingGalleryPage(
                      title: 'Календарь платежей',
                      subtitle: 'Весь ${now.year} год',
                      year: now.year,
                      now: now,
                      occurrences: metrics.yearOccurrences,
                      periodArcOccurrences: metrics.upcomingPayments,
                      counterValue: metrics.yearOccurrences.length,
                      selectedMonth: _selectedMonth,
                      showPeriodArcs: true,
                      showCalendarLogos: true,
                      onMonthSelected: (month) {
                        setState(() => _selectedMonth = month);
                      },
                    ),
                  ],
                ),
              ),
              if (isAdminDateSimulator(userName)) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                _AdminDateSimulator(
                  dayOffset: _debugDayOffset,
                  selectedDate: now,
                  onChanged: (offset) {
                    setState(() => _debugDayOffset = offset);
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xxs),
              _GalleryPageIndicator(selectedPage: _ringPage),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Text(
                    _ringPage == 0
                        ? 'Дуги показывают срок до следующего списания'
                        : 'Свайпните вправо, чтобы вернуться к ближайшим',
                    key: ValueKey<int>(_ringPage),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _SelectedMonthPayments(
                    key: ValueKey<int>(_selectedMonth),
                    occurrences: selectedOccurrences,
                    onTap: (subscription) {
                      context.push('/subscriptions/${subscription.id}');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(
          title: 'Динамика расходов',
          subtitle: 'План и факт за последние 6 месяцев',
          onTap: () => showDynamicsDetailSheet(
            context: context,
            points: metrics.spendingByMonth,
            payments: payments,
            subscriptions: subscriptions,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: SpendingBarChart(
            points: metrics.spendingByMonth,
            onBarSelected: (point) => showMonthSpendingSheet(
              context: context,
              month: point.month,
              payments: payments,
              subscriptions: subscriptions,
              plannedInCents: point.plannedAmountInCents,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminDateSimulator extends StatelessWidget {
  const _AdminDateSimulator({
    required this.dayOffset,
    required this.selectedDate,
    required this.onChanged,
  });

  final int dayOffset;
  final DateTime selectedDate;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Column(
      children: <Widget>[
        Text(
          AppFormatters.fullDate(selectedDate),
          style: theme.textTheme.labelLarge?.copyWith(
            color: primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: primary,
            inactiveTrackColor: primary.withValues(alpha: 0.22),
            thumbColor: primary,
            overlayColor: primary.withValues(alpha: 0.16),
          ),
          child: Slider(
            value: dayOffset.toDouble(),
            min: -365,
            max: 365,
            divisions: 730,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
      ],
    );
  }
}

class _RingGalleryPage extends StatelessWidget {
  const _RingGalleryPage({
    required this.title,
    required this.subtitle,
    required this.year,
    required this.now,
    required this.occurrences,
    required this.periodArcOccurrences,
    required this.counterValue,
    required this.selectedMonth,
    required this.onMonthSelected,
    this.showPeriodArcs = false,
    this.showCalendarLogos = true,
  });

  final String title;
  final String subtitle;
  final int year;
  final DateTime now;
  final List<PaymentOccurrence> occurrences;
  final List<PaymentOccurrence> periodArcOccurrences;
  final int counterValue;
  final int selectedMonth;
  final ValueChanged<int> onMonthSelected;
  final bool showPeriodArcs;
  final bool showCalendarLogos;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$counterValue',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: primary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BerryCalendarRing(
            year: year,
            now: now,
            occurrences: occurrences,
            periodArcOccurrences: periodArcOccurrences,
            selectedMonth: selectedMonth,
            showPeriodArcs: showPeriodArcs,
            showCalendarLogos: showCalendarLogos,
            onMonthSelected: onMonthSelected,
          ),
        ),
      ],
    );
  }
}

class _GalleryPageIndicator extends StatelessWidget {
  const _GalleryPageIndicator({required this.selectedPage});

  final int selectedPage;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var index = 0; index < 2; index++) ...<Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: selectedPage == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: selectedPage == index
                  ? primary
                  : Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          if (index == 0) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.metrics});

  final OverviewMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final next = metrics.upcomingPayments.firstOrNull;
    final accent = context.accentTheme;

    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: accent.gradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Запланировано в этом месяце',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.money(metrics.plannedThisMonthInCents),
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Фактически потрачено: '
            '${AppFormatters.money(metrics.actualThisMonthInCents)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryCaption(
                  label: 'Среднее',
                  value:
                      '${AppFormatters.money(metrics.averageMonthlyPlannedInCents)} / мес',
                ),
              ),
              if (next != null) ...<Widget>[
                Container(
                  width: 1,
                  height: 38,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _NextPaymentCaption(occurrence: next)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NextPaymentCaption extends StatelessWidget {
  const _NextPaymentCaption({required this.occurrence});

  final PaymentOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final subscription = occurrence.subscription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Ближайшее',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: <Widget>[
            ServiceLogo(
              name: subscription.name,
              logoKey: subscription.logo,
              category: subscription.category,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                subscription.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCaption extends StatelessWidget {
  const _SummaryCaption({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SelectedMonthPayments extends StatefulWidget {
  const _SelectedMonthPayments({
    required this.occurrences,
    required this.onTap,
    super.key,
  });

  final List<PaymentOccurrence> occurrences;
  final ValueChanged<Subscription> onTap;

  @override
  State<_SelectedMonthPayments> createState() => _SelectedMonthPaymentsState();
}

class _SelectedMonthPaymentsState extends State<_SelectedMonthPayments> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.occurrences.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Center(
          child: Text(
            'В этом месяце списаний нет',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final visible = _expanded ? widget.occurrences : widget.occurrences.take(3);
    final brightness = Theme.of(context).brightness;
    return Column(
      children: <Widget>[
        for (final occurrence in visible)
          Builder(
            builder: (context) {
              final subscription = occurrence.subscription;
              final visual = resolveSubscriptionVisual(
                name: subscription.name,
                logoKey: subscription.logo,
                category: subscription.category,
                brightness: brightness,
              );
              return GlassPaymentRow(
                leading: ServiceLogo(
                  name: subscription.name,
                  logoKey: subscription.logo,
                  category: subscription.category,
                  size: 40,
                ),
                title: subscription.name,
                subtitle: AppFormatters.shortDate(occurrence.date),
                trailing: AppFormatters.money(subscription.priceInCents),
                trailingColor: visual.primary,
                accentColor: visual.glow,
                onTap: () => widget.onTap(subscription),
              );
            },
          ),
        if (widget.occurrences.length > 3)
          TextButton.icon(
            onPressed: () {
              setState(() => _expanded = !_expanded);
            },
            icon: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
            label: Text(
              _expanded ? 'Свернуть' : 'Ещё ${widget.occurrences.length - 3}',
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            Expanded(child: content),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingOverview extends StatelessWidget {
  const _LoadingOverview();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _OverviewError extends StatelessWidget {
  const _OverviewError();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Не удалось собрать обзор',
      description: 'Данные остались в безопасности на устройстве',
      icon: Icons.sync_problem_rounded,
    );
  }
}
