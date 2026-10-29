import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../data/kyc/kyc_repository.dart';
import '../../features/kyc/kyc_page.dart';
import '../../state/auth_scope.dart';
import '../../state/feature_flags_scope.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../feature_flags/app_feature.dart';
import 'transaction_authorizer.dart';

/// Whether bill payments, and this biller in particular, are switched on.
bool billFeatureEnabled(BuildContext context, String? biller) {
  if (!FeatureFlagsScope.enabled(context, AppFeature.bills)) return false;
  final feature = biller == null
      ? AppFeature.schoolFees
      : (AppFeature.forBillId(biller) ?? AppFeature.schoolFees);
  return FeatureFlagsScope.enabled(context, feature);
}

/// Runs [action] only after the local rules pass.
///
/// The action itself must call the platform authorize method (the money
/// repository does). A denial is shown here. When the platform asks for a
/// second factor, the code is collected once and [action] is retried.
Future<T?> runMoneyMovement<T>(
  BuildContext context, {
  required TransactionKind kind,
  required double amount,
  required String currency,
  String? biller,
  required Future<T> Function({String? mfaCode, String? challengeId}) action,
}) async {
  final auth = AuthScope.maybeRead(context);
  final enabled = switch (kind) {
    TransactionKind.send => FeatureFlagsScope.enabled(context, AppFeature.send),
    TransactionKind.deposit => FeatureFlagsScope.enabled(
      context,
      AppFeature.deposit,
    ),
    TransactionKind.withdrawal => FeatureFlagsScope.enabled(
      context,
      AppFeature.withdrawal,
    ),
    TransactionKind.bill => billFeatureEnabled(context, biller),
  };
  final preview = TransactionAuthorizer.preview(
    token: auth?.sessionToken,
    kyc: auth?.user?.kyc,
    featureEnabled: enabled,
    amount: amount,
    currency: currency,
  );
  if (!preview.allowed) {
    if (context.mounted) await showTransactionBlocked(context, preview);
    return null;
  }
  try {
    return await action();
  } on TransactionBlocked catch (blocked) {
    if (!context.mounted) return null;
    if (blocked.decision.code == TransactionCodes.mfaRequired) {
      final code = await _askMfaCode(context);
      if (code == null || !context.mounted) return null;
      try {
        return await action(
          mfaCode: code,
          challengeId: blocked.decision.challengeId,
        );
      } on TransactionBlocked catch (again) {
        if (context.mounted) {
          await showTransactionBlocked(context, again.decision);
        }
        return null;
      }
    }
    await showTransactionBlocked(context, blocked.decision);
    return null;
  }
}

Future<void> showTransactionBlocked(
  BuildContext context,
  TransactionDecision decision,
) {
  final limits = decision.limits?.summary;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: KpColors.surface,
    showDragHandle: true,
    builder: (sheet) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _title(decision.code),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              decision.message.isEmpty
                  ? 'This payment cannot be completed.'
                  : decision.message,
            ),
            if (limits != null && limits.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                limits,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: KpColors.muted),
              ),
            ],
            const SizedBox(height: 14),
            if (decision.code == TransactionCodes.kycRequired)
              KpButton(
                label: 'Verify identity',
                onTap: () {
                  Navigator.of(sheet).pop();
                  final token = AuthScope.maybeRead(context)?.sessionToken;
                  if (token == null || token.isEmpty) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => KycPage(
                        repository: KycRepository(
                          baseUrl: kApiBase,
                          token: token,
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              KpButton(label: 'Close', onTap: () => Navigator.of(sheet).pop()),
          ],
        ),
      );
    },
  );
}

String _title(String code) {
  return switch (code) {
    TransactionCodes.kycRequired => 'Verification required',
    TransactionCodes.limitReached => 'Limit reached',
    TransactionCodes.featureDisabled => 'Service turned off',
    TransactionCodes.mfaRequired => 'Extra confirmation needed',
    TransactionCodes.accountRestricted => 'Account restricted',
    TransactionCodes.network => 'Could not confirm',
    _ => 'Payment not allowed',
  };
}

Future<String?> _askMfaCode(BuildContext context) {
  final code = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialog) {
      return AlertDialog(
        title: const Text('Confirm it\'s you'),
        content: TextField(
          controller: code,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Authentication code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = code.text.trim();
              Navigator.of(dialog).pop(value.isEmpty ? null : value);
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  ).whenComplete(code.dispose);
}
