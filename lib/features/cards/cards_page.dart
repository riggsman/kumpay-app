import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../data/cards/cards_repository.dart';
import '../../theme/kp_theme.dart';
import '../../widgets/kp_controls.dart';
import '../../widgets/kp_shell.dart';

/// The signed-in client's virtual cards. The first card is free after identity approval.
class CardsPage extends StatefulWidget {
  const CardsPage({super.key, required this.repository});

  final CardsRepository repository;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  List<VirtualCard> _cards = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cards = await widget.repository.list();
      if (mounted) setState(() => _cards = cards);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create(String type) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.create(type);
      if (!mounted) return;
      await _reload();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KpPage(
      header: KpSimpleHeader(
        title: 'Virtual cards',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      children: [
        const KpScreenTitle(
          'Your cards',
          'The name on the card is your account name. You can hold one USD card and one XAF card. The first card is free once your identity is approved.',
        ),
        if (_loading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          KpInlineError(_error!),
        ],
        const SizedBox(height: 14),
        if (!_loading && _cards.isEmpty)
          const Text(
            'You do not have a card yet.',
            style: TextStyle(color: KpColors.muted, fontSize: 12),
          ),
        for (final card in _cards) ...[
          _CardTile(card: card),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        KpButton(
          label: 'Create USD card',
          busy: _busy,
          onTap: _busy ? null : () => _create('usd'),
        ),
        const SizedBox(height: 8),
        KpButton(
          label: 'Create XAF card',
          style: KpButtonStyle.outline,
          busy: _busy,
          onTap: _busy ? null : () => _create('xaf'),
        ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});

  final VirtualCard card;

  @override
  Widget build(BuildContext context) {
    final money = card.currency == 'USD'
        ? '\$${card.amount.toStringAsFixed(2)}'
        : '${card.amount.toStringAsFixed(0)} ${card.currency}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KpColors.primary,
        borderRadius: BorderRadius.circular(KpRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.label, style: const TextStyle(color: Color(0xFFFDF9EE), fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            '•••• ${card.last4}',
            style: const TextStyle(color: Color(0xFFFDF9EE), fontSize: 18, letterSpacing: 1.4, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${card.type.toUpperCase()} · $money · ${card.status}',
            style: const TextStyle(color: Color(0xFFE7D7A8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

String _message(Object error) {
  if (error is ApiException) {
    return switch (error.code) {
      'KYC_REQUIRED' => 'Verify your identity before creating a card.',
      'CARD_TYPE_LIMIT' => 'You already have a card of this type.',
      'INSUFFICIENT_FUNDS' => 'Your balance is too low for this card fee.',
      _ => error.message,
    };
  }
  return "Couldn't reach KumPay. Check your connection and try again.";
}
