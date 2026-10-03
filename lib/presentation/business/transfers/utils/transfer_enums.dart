import 'package:easy_localization/easy_localization.dart';
import 'package:hangout/generated/locale_keys.g.dart';

enum TransferType {
  business,
  venue;

  String get wire => switch (this) {
        TransferType.business => 'BUSINESS',
        TransferType.venue => 'VENUE',
      };

  static TransferType? fromWire(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'BUSINESS':
        return TransferType.business;
      case 'VENUE':
        return TransferType.venue;
      default:
        return null;
    }
  }
}

enum TransferStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired;

  String get wire => name;

  static TransferStatus? fromWire(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'pending':
        return TransferStatus.pending;
      case 'accepted':
        return TransferStatus.accepted;
      case 'declined':
        return TransferStatus.declined;
      case 'cancelled':
        return TransferStatus.cancelled;
      case 'expired':
        return TransferStatus.expired;
      default:
        return null;
    }
  }

  bool get isTerminal => this != TransferStatus.pending;
}

String transferStatusLabelAr(TransferStatus s) {
  switch (s) {
    case TransferStatus.pending:
      return LocaleKeys.business_transfers_status_pending.tr();
    case TransferStatus.accepted:
      return LocaleKeys.business_transfers_status_accepted.tr();
    case TransferStatus.declined:
      return LocaleKeys.business_transfers_status_declined.tr();
    case TransferStatus.cancelled:
      return LocaleKeys.business_transfers_status_cancelled.tr();
    case TransferStatus.expired:
      return LocaleKeys.business_transfers_status_expired.tr();
  }
}
