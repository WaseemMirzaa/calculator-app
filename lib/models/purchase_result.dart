/// Result of launching a Google Play subscription purchase flow.
sealed class PurchaseResult {
  const PurchaseResult();

  /// Google Play purchase sheet was shown; entitlement updates via purchase stream.
  const factory PurchaseResult.launched() = PurchaseLaunched;

  /// Purchase could not be started.
  const factory PurchaseResult.failed(String message) = PurchaseFailed;
}

final class PurchaseLaunched extends PurchaseResult {
  const PurchaseLaunched();
}

final class PurchaseFailed extends PurchaseResult {
  const PurchaseFailed(this.message);
  final String message;
}
