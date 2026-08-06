import 'package:fintech_wallet/core/network/api_endpoints.dart';
import 'package:fintech_wallet/features/transfer/data/datasource/transfer_remote_datasource.dart';
import 'package:fintech_wallet/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:fintech_wallet/features/transfer/data/model/recipient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/transfer_repository.dart';

/// Immutable snapshot of everything the Transfer screen needs to render.
/// Same convention as `TopUpState`/`AuthState` — replaced wholesale via
/// [copyWith], one state-management pattern across the whole app.
class TransferState {
  final Recipient? recipient;
  final double amount;
  final String currency;
  final String? note;
  final bool loadingRecipient;
  final bool submitting;
  final String? errorMessage;

  const TransferState({
    this.recipient,
    this.amount = 0.0,
    this.currency = 'USD',
    this.note,
    this.loadingRecipient = true,
    this.submitting = false,
    this.errorMessage,
  });

  TransferState copyWith({
    Recipient? recipient,
    double? amount,
    String? currency,
    String? note,
    bool? loadingRecipient,
    bool? submitting,
    String? errorMessage,
  }) {
    return TransferState(
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      note: note ?? this.note,
      loadingRecipient: loadingRecipient ?? this.loadingRecipient,
      submitting: submitting ?? this.submitting,
      // Same deliberate exception as TopUpState/AuthState: not preserved
      // with `??` like the other fields, so any copyWith call that doesn't
      // pass this explicitly resets it to null.
      errorMessage: errorMessage,
    );
  }
}

/// No quick-amount chips here (unlike Top-up) — the Transfer mockup shows a
/// plain typed amount, so there's a `setAmount` setter instead of
/// `selectQuickAmount`. Everything else mirrors `TopUpNotifier`.
class TransferNotifier extends StateNotifier<TransferState> {
  final TransferRepository _repository;

  TransferNotifier(this._repository) : super(const TransferState());

  /// Called once from the screen's `initState`, same role as
  /// `loadPaymentMethods` in `TopUpNotifier`.
  Future<void> loadRecipient() async {
    state = state.copyWith(loadingRecipient: true, errorMessage: null);

    try {
      final recipient = await _repository.getDefaultRecipient();
      state = state.copyWith(recipient: recipient, loadingRecipient: false);
    } catch (e) {
      state = state.copyWith(
        loadingRecipient: false,
        errorMessage: 'Could not load recipient.',
      );
    }
  }

  /// Called when the user picks a different recipient from
  /// `RecipientPickerScreen` — updates state directly, no network round
  /// trip needed since the picker already fetched the full [Recipient].
  void setRecipient(Recipient recipient) {
    state = state.copyWith(recipient: recipient);
  }

  void setAmount(double value) {
    state = state.copyWith(amount: value);
  }

  void setNote(String value) {
    state = state.copyWith(note: value);
  }

  /// Returns the result so the screen decides what to do next (navigate,
  /// show an error) — the notifier never triggers navigation itself.
  Future<TransferResult?> submit() async {
    final recipient = state.recipient;
    if (recipient == null || state.amount <= 0) return null;

    state = state.copyWith(submitting: true);

    try {
      final result = await _repository.submitTransfer(
        recipient: recipient,
        amount: state.amount,
        currency: state.currency,
        note: state.note,
      );
      return result;
    } catch (e) {
      return const TransferResult(
        success: false,
        message: 'Something went wrong.',
      );
    } finally {
      state = state.copyWith(submitting: false);
    }
  }
}

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  final dataSource = HttpTransferRemoteDataSource(
    baseUrl: ApiEndpoints.baseUrl,
  );
  return TransferRepositoryImpl(dataSource);
});

final transferProvider = StateNotifierProvider<TransferNotifier, TransferState>(
  (ref) {
    final repository = ref.watch(transferRepositoryProvider);
    return TransferNotifier(repository);
  },
);
