import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/nearo_theme.dart';
import 'otp_screen.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController(text: '+995');
  final _formKey = GlobalKey<FormState>();
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final locale = ref.watch(appLocaleProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: NearoTheme.pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: NearoTheme.glassDecoration(
                    radius: 30,
                    borderColor: NearoTheme.neon.withValues(alpha: 0.22),
                    glowColor: NearoTheme.neon,
                    glowOpacity: 0.16,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.t('app.name'),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: NearoTheme.neon,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.t('app.tagline'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SegmentedButton<Locale>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              minimumSize: WidgetStatePropertyAll(
                                Size(112, 42),
                              ),
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 14),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            segments: [
                              ButtonSegment<Locale>(
                                value: const Locale('en'),
                                label: Text(
                                  l10n.t('language.english'),
                                  softWrap: false,
                                ),
                              ),
                              ButtonSegment<Locale>(
                                value: const Locale('ka'),
                                label: Text(
                                  l10n.t('language.georgian'),
                                  softWrap: false,
                                ),
                              ),
                            ],
                            selected: {locale},
                            onSelectionChanged: (selection) {
                              ref
                                  .read(appLocaleProvider.notifier)
                                  .setLocale(selection.first);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.t('auth.phoneHelp'),
                          style: const TextStyle(color: NearoTheme.mutedText),
                        ),
                        const SizedBox(height: 28),
                        if (!firebaseReady) const _DemoNotice(),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: l10n.t('auth.phoneNumber'),
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            final phone = value?.trim() ?? '';
                            if (phone.length < 8 || !phone.startsWith('+')) {
                              return l10n.t('auth.phoneValidation');
                            }
                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _loading ? null : _sendCode,
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.t('auth.sendSmsCode')),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => ref
                                    .read(authControllerProvider.notifier)
                                    .continueAsDemo(),
                          child: Text(l10n.t('auth.continueDemo')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await ref
          .read(authControllerProvider.notifier)
          .requestSmsCode(phoneNumber: _phoneController.text);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OtpScreen(
            phoneNumber: _phoneController.text.trim(),
            verificationId: session.verificationId,
            resendToken: session.resendToken,
          ),
        ),
      );
    } catch (error) {
      setState(() => _error = 'Could not send SMS code. $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NearoTheme.neon.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NearoTheme.neon.withValues(alpha: 0.25)),
      ),
      child: Text(AppLocalizations.of(context).t('auth.demoNotice')),
    );
  }
}
