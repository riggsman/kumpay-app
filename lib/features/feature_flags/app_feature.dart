/// Services the platform can turn on or off.
///
/// [key] is the wire value in `GET /api/features`. [defaultEnabled] is used
/// only until the first successful snapshot, and for any key the snapshot
/// omits. A missing backend therefore leaves the current app usable; an
/// explicit `false` hides the service.
enum AppFeature {
  send('send', 'Send money', true),
  deposit('deposit', 'Top up / deposit', true),
  withdrawal('withdrawal', 'Withdrawal', true),
  bills('bills', 'Bill payments', true),
  schoolFees('school_fees', 'School fee payment', true),
  eneo('eneo', 'ENEO', true),
  camwater('camwater', 'CAMWATER', true),
  canalPlus('canal_plus', 'Canal+', true),
  dstv('dstv', 'DStv', true),
  airtime('airtime', 'Airtime', true),
  internet('internet', 'Internet', true),
  taxes('taxes', 'Taxes', true),
  biometrics('biometrics', 'Biometric login', true),
  mfa('mfa', 'Multi-factor authentication', true);

  const AppFeature(this.key, this.label, this.defaultEnabled);

  final String key;
  final String label;
  final bool defaultEnabled;

  static AppFeature? byKey(String key) {
    for (final feature in values) {
      if (feature.key == key) return feature;
    }
    return null;
  }

  /// Maps a biller id from the app or the API onto its feature flag.
  static AppFeature? forBillId(String id) {
    return switch (id.trim().toLowerCase()) {
      'eneo' => AppFeature.eneo,
      'camwater' => AppFeature.camwater,
      'canal' || 'canal_plus' || 'canal+' => AppFeature.canalPlus,
      'dstv' => AppFeature.dstv,
      'school_fees' || 'fees' || 'school' => AppFeature.schoolFees,
      'airtime' => AppFeature.airtime,
      'internet' => AppFeature.internet,
      'taxes' || 'tax' => AppFeature.taxes,
      _ => null,
    };
  }
}
