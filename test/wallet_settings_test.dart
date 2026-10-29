import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kumpay_uiux/core/api_client.dart';
import 'package:kumpay_uiux/data/money/money_repository.dart';
import 'package:kumpay_uiux/features/wallet/wallet_settings.dart';
import 'package:kumpay_uiux/screens/wallet/devices_page.dart';
import 'package:kumpay_uiux/screens/wallet/linked_accounts_page.dart';
import 'package:kumpay_uiux/screens/wallet/wallet_settings_sheet.dart';
import 'package:kumpay_uiux/theme/kp_theme.dart';

void main() {
  test('close wallet stays off unless the database sends true', () {
    final hidden = WalletSettings.fromJson({
      'defaultCurrency': 'FCFA',
      'currencies': ['XAF'],
      'accounts': [
        {
          'id': 'acc-1',
          'label': 'MTN Mobile Money',
          'kind': 'momo',
          'detail': '+237 677 ••• 456',
        },
      ],
    });
    final shown = WalletSettings.fromJson({
      'defaultCurrency': 'USD',
      'closeWalletEnabled': true,
      'currencies': ['USD'],
    });

    expect(hidden.closeWalletEnabled, isFalse);
    expect(hidden.defaultCurrency, 'XAF');
    expect(hidden.defaultCurrencyLabel, 'FCFA');
    expect(hidden.offers('USD'), isFalse);
    expect(hidden.accounts.single.detail, '+237 677 ••• 456');
    expect(shown.closeWalletEnabled, isTrue);
    expect(shown.defaultCurrencyLabel, 'USD');
  });

  test('a failed refresh keeps the cached default currency', () async {
    final cache = MemoryWalletSettingsCache();
    await cache.write(
      const WalletSettings(
        defaultCurrency: 'USD',
        closeWalletEnabled: false,
        currencies: ['USD'],
        accounts: [],
      ),
    );
    final repository = _repository(_Api(), cache: cache, failSettings: true);

    final settings = await repository.walletSettings();

    expect(settings.defaultCurrency, 'USD');
    expect(settings.closeWalletEnabled, isFalse);
  });

  test('settings from the database replace the cache', () async {
    final cache = MemoryWalletSettingsCache();
    await cache.write(WalletSettings.fallback);
    final repository = _repository(
      _Api(
        settings: {
          'defaultCurrency': 'XAF',
          'closeWalletEnabled': false,
          'currencies': ['XAF', 'USD'],
          'accounts': [],
        },
      ),
      cache: cache,
    );

    final settings = await repository.walletSettings();

    expect(settings.defaultCurrencyLabel, 'FCFA');
    expect(settings.closeWalletEnabled, isFalse);
    expect((await cache.read())?.defaultCurrency, 'XAF');
  });

  test('adding and removing an account uses the wallet account methods',
      () async {
    final api = _Api(
      settings: {
        'defaultCurrency': 'XAF',
        'accounts': [
          {
            'id': 'acc-1',
            'label': 'MTN Mobile Money',
            'kind': 'momo',
            'detail': '••• 456',
          },
        ],
      },
    );
    final repository = _repository(api, cache: MemoryWalletSettingsCache());

    final created = await repository.addAccount(
      label: 'Orange Money',
      kind: 'momo',
      detail: '+237699000118',
    );
    await repository.removeAccount('acc-1');

    expect(created.id, 'acc-2');
    expect(api.bodies.first['detail'], '+237699000118');
    expect(api.methods, contains('DELETE'));
    expect(api.paths, contains('/api/me/wallet/accounts/acc-1'));
  });

  test('a device can be renamed and removed', () async {
    final api = _Api();
    final repository = _repository(api, cache: MemoryWalletSettingsCache());

    final renamed = await repository.renameDevice(id: 'dev-1', label: 'Work');
    await repository.removeDevice('dev-1');

    expect(renamed.label, 'Work');
    expect(api.paths, contains('/api/auth/devices/dev-1'));
    expect(api.methods, containsAll(['PUT', 'DELETE']));
  });

  testWidgets('default currency is locked and close wallet stays hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KpTheme.light(),
        home: const Scaffold(
          body: WalletSettingsSheet(initial: WalletSettings.fallback),
        ),
      ),
    );

    expect(find.text('FCFA'), findsOneWidget);
    expect(find.text('Close wallet'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('close wallet appears only when the database enables it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KpTheme.light(),
        home: const Scaffold(
          body: WalletSettingsSheet(
            initial: WalletSettings(
              defaultCurrency: 'XAF',
              closeWalletEnabled: true,
              currencies: ['XAF'],
              accounts: [],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Close wallet'), findsOneWidget);
  });

  testWidgets('accounts can be added and removed from the management screen', (
    tester,
  ) async {
    final api = _Api(
      settings: {
        'defaultCurrency': 'XAF',
        'accounts': [
          {
            'id': 'acc-1',
            'label': 'MTN Mobile Money',
            'kind': 'momo',
            'detail': '••• 456',
          },
        ],
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: KpTheme.light(),
        home: Material(
          child: LinkedAccountsPage(
            repository: _repository(api, cache: MemoryWalletSettingsCache()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MTN Mobile Money'), findsOneWidget);
    expect(find.text('Add account'), findsOneWidget);

    await tester.tap(find.byKey(const Key('remove-account-acc-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(api.paths, contains('/api/me/wallet/accounts/acc-1'));
    expect(find.text('None yet'), findsOneWidget);
  });

  testWidgets('a linked device can be renamed', (tester) async {
    final api = _Api();
    await tester.pumpWidget(
      MaterialApp(
        theme: KpTheme.light(),
        home: Material(
          child: DevicesPage(
            repository: _repository(api, cache: MemoryWalletSettingsCache()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.byKey(const Key('remove-device-dev-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('rename-device-dev-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Work');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(api.bodies.last['label'], 'Work');
    expect(find.text('Work'), findsWidgets);
  });
}

MoneyRepository _repository(
  _Api api, {
  required MemoryWalletSettingsCache cache,
  bool failSettings = false,
}) {
  api.failSettings = failSettings;
  return MoneyRepository(
    baseUrl: 'http://example.test',
    token: 'session',
    api: ApiClient(baseUrl: 'http://example.test', client: api),
    settingsCache: cache,
    authorizer: null,
  );
}

class _Api extends http.BaseClient {
  _Api({Map<String, dynamic>? settings})
      : settings = {
          'defaultCurrency': 'XAF',
          'closeWalletEnabled': false,
          'currencies': ['XAF', 'USD'],
          'accounts': <Map<String, dynamic>>[],
          ...?settings,
        };

  Map<String, dynamic> settings;
  var failSettings = false;
  var deviceLabel = 'Kitchen';
  final paths = <String>[];
  final methods = <String>[];
  final bodies = <Map<String, dynamic>>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    paths.add(request.url.path);
    methods.add(request.method);
    Map<String, dynamic>? body;
    if (request is http.Request && request.body.isNotEmpty) {
      body = jsonDecode(request.body) as Map<String, dynamic>;
      bodies.add(body);
    }
    if (failSettings && request.url.path.endsWith('/settings')) {
      throw StateError('offline');
    }
    if (request.url.path.endsWith('/wallet/settings')) {
      return _json(settings);
    }
    if (request.method == 'POST' && request.url.path.endsWith('/accounts')) {
      settings = {
        ...settings,
        'accounts': [
          ...(settings['accounts'] as List),
          {
            'id': 'acc-2',
            'label': body?['label'],
            'kind': body?['kind'],
            'detail': '••• 118',
          },
        ],
      };
      return _json({
        'id': 'acc-2',
        'label': body?['label'],
        'kind': body?['kind'],
        'detail': '••• 118',
      });
    }
    if (request.method == 'DELETE' && request.url.path.contains('/accounts/')) {
      final accounts = [
        for (final entry in settings['accounts'] as List)
          if (entry is Map && !request.url.path.endsWith('/${entry['id']}'))
            entry,
      ];
      settings = {...settings, 'accounts': accounts};
      return _json({});
    }
    if (request.method == 'GET' && request.url.path.endsWith('/devices')) {
      return _json({
        'items': [
          {
            'id': 'dev-1',
            'label': deviceLabel,
            'model': 'Pixel',
            'platform': 'Android',
            'current': false,
          },
        ],
      });
    }
    if (request.method == 'PUT' && request.url.path.contains('/devices/')) {
      deviceLabel = body?['label']?.toString() ?? deviceLabel;
      return _json({
        'id': 'dev-1',
        'label': deviceLabel,
        'model': 'Pixel',
        'platform': 'Android',
        'current': false,
      });
    }
    if (request.method == 'DELETE' && request.url.path.contains('/devices/')) {
      return _json({});
    }
    return _json({});
  }

  http.StreamedResponse _json(Object body) {
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(jsonEncode(body))),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}
