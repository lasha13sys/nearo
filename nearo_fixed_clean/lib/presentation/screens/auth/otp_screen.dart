import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('auth.verifyPhone'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.enterCodeSentTo(widget.phoneNumber),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: l10n.t('auth.smsCode'),
                prefixIcon: const Icon(Icons.sms_outlined),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: authState.isLoading ? null : _verify,
              child: authState.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.t('auth.verifyAndContinue')),
            ),
            TextButton(
              onPressed: authState.isLoading ? null : _resend,
              child: Text(l10n.t('auth.resendCode')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verify() async {
    setState(() => _error = null);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifySmsCode(
            verificationId: widget.verificationId,
            smsCode: _codeController.text,
            phoneNumber: widget.phoneNumber,
          );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      setState(() => _error = 'Invalid or expired code. $error');
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestSmsCode(
            phoneNumber: widget.phoneNumber,
            resendToken: widget.resendToken,
          );
    } catch (error) {
      setState(() => _error = 'Could not resend code. $error');
    }
  }
}
