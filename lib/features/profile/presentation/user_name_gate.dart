import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/subberry_logo.dart';
import '../application/user_profile_controller.dart';

class UserNameGate extends ConsumerWidget {
  const UserNameGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    if (profile.isLoading) {
      return const AppBackground(child: Center(child: SubberryLogo(size: 82)));
    }
    if (profile.name != null) return child;
    return Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (_) => const _UserNameOnboarding()),
    );
  }
}

class _UserNameOnboarding extends ConsumerStatefulWidget {
  const _UserNameOnboarding();

  @override
  ConsumerState<_UserNameOnboarding> createState() =>
      _UserNameOnboardingState();
}

class _UserNameOnboardingState extends ConsumerState<_UserNameOnboarding> {
  final _controller = TextEditingController();
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChanged);
  }

  void _handleChanged() {
    final canContinue = _controller.text.trim().isNotEmpty;
    if (canContinue != _canContinue) {
      setState(() => _canContinue = canContinue);
    }
  }

  Future<void> _submit() async {
    if (!_canContinue) return;
    final saved = await ref
        .read(userProfileProvider.notifier)
        .saveName(_controller.text);
    if (!saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось сохранить имя')));
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SubberryLogo(size: 96),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Давайте познакомимся 🍓',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Как вас зовут?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    GlassCard(
                      strong: true,
                      child: Column(
                        children: <Widget>[
                          TextField(
                            controller: _controller,
                            autofocus: true,
                            maxLength: 40,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'Ваше имя',
                              prefixIcon: Icon(Icons.person_rounded),
                              counterText: '',
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          GlassButton(
                            label: profile.isSaving
                                ? 'Сохраняем...'
                                : 'Продолжить',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: !_canContinue || profile.isSaving
                                ? null
                                : _submit,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
