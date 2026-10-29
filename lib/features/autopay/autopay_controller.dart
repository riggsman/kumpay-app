import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../data/money/money_repository.dart';
import 'autopay_plan.dart';

/// Holds the tenant's autopay plan on the phone.
///
/// A new [MoneyRepository] is created for every call, so the plan lives here
/// and both Profile and Pay bills read the same copy. When `/api/me/autopay`
/// is missing, or KumPay cannot be reached, the phone keeps this copy.
class AutopayController extends ChangeNotifier {
  AutopayPlan plan = AutopayPlan.off;

  String? _token;
  var _loaded = false;

  /// Loads the server plan once per session token.
  ///
  /// Signed-out use keeps the plan already on the phone, which starts off.
  Future<void> ensureLoaded(MoneyRepository? repo) async {
    final token = repo?.token;
    if (_loaded && _token == token) return;
    _token = token;
    _loaded = true;
    if (repo == null) {
      notifyListeners();
      return;
    }
    try {
      final remote = await repo.fetchAutopay();
      if (remote != null) plan = remote;
    } catch (_) {
      // Keep the plan already on the phone.
    }
    notifyListeners();
  }

  /// Saves [next] locally, then to the server when that method exists.
  Future<void> update(MoneyRepository? repo, AutopayPlan next) async {
    final previous = plan;
    plan = next;
    notifyListeners();
    if (repo == null) return;
    try {
      final saved = await repo.saveAutopay(next);
      if (saved != null) {
        plan = saved;
        notifyListeners();
      }
    } on ApiException catch (error) {
      // 404: the method is not deployed. No status: the phone could not
      // reach KumPay. Either way the holder already chose this plan, so
      // it stays on the device. A real response restores the previous plan.
      if (error.status == null || error.status == 404) return;
      plan = previous;
      notifyListeners();
      rethrow;
    }
  }

  /// Clears the in-memory plan. Tests use this between cases.
  void reset() {
    plan = AutopayPlan.off;
    _token = null;
    _loaded = false;
    notifyListeners();
  }
}

/// Shared plan for the signed-in session and the signed-out design preview.
final autopayController = AutopayController();
