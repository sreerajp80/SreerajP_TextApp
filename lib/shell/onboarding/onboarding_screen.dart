import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'onboarding_controller.dart';

/// A short, skippable first-run intro (task 2.4).
///
/// Shown only when onboarding is not yet complete. "Skip" and "Get started"
/// both mark it complete so it never appears again.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const int _pageCount = 3;

  List<_IntroPage> _pages(AppLocalizations l10n) => [
        _IntroPage(
          icon: Icons.edit_document,
          title: l10n.onboarding1Title,
          body: l10n.onboarding1Body,
        ),
        _IntroPage(
          icon: Icons.lock_outline,
          title: l10n.onboarding2Title,
          body: l10n.onboarding2Body,
        ),
        _IntroPage(
          icon: Icons.sync_alt,
          title: l10n.onboarding3Title,
          body: l10n.onboarding3Body,
        ),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingControllerProvider.notifier).complete();

  bool get _isLast => _page == _pageCount - 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => pages[i],
              ),
            ),
            _Dots(count: pages.length, active: _page),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(
                    _isLast ? l10n.onboardingGetStarted : l10n.onboardingNext,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _IntroPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text(title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            body,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;

  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
