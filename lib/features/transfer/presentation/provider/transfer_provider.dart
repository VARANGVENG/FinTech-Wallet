import 'package:fintech_wallet/core/network/api_endpoints.dart';
import 'package:fintech_wallet/features/transfer/data/datasource/transfer_remote_datasource.dart';
import 'package:fintech_wallet/features/transfer/data/model/wallet.dart';
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
  final bool submitting;
  final List<Wallet> wallets;
  final Wallet? selectedWallet;
  final bool loadingWallets;

  const TransferState({
    this.recipient,
    this.amount = 0.0,
    this.currency = 'USD',
    this.note,
    this.submitting = false,
    this.wallets = const [],
    this.selectedWallet,
    this.loadingWallets = true,
  });

  TransferState copyWith({
    Recipient? recipient,
    double? amount,
    String? currency,
    String? note,
    bool? submitting,
    List<Wallet>? wallets,
    Wallet? selectedWallet,
    bool? loadingWallets,
  }) {
    return TransferState(
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      note: note ?? this.note,
      submitting: submitting ?? this.submitting,
      wallets: wallets ?? this.wallets,
      selectedWallet: selectedWallet ?? this.selectedWallet,
      loadingWallets: loadingWallets ?? this.loadingWallets,
    );
  }
}

/// No quick-amount chips here (unlike Top-up) — the Transfer mockup shows a
/// plain typed amount, so there's a `setAmount` setter instead of
/// `selectQuickAmount`. Everything else mirrors `TopUpNotifier`.
class TransferNotifier extends StateNotifier<TransferState> {
  final TransferRepository _repository;

  TransferNotifier(this._repository) : super(const TransferState());

  void setAmount(double value) {
    state = state.copyWith(amount: value);
  }

  void setNote(String value) {
    state = state.copyWith(note: value);
  }

  /// Called when the user picks a recipient from the recipient-picker
  /// bottom sheet — updates state directly, no network round trip needed
  /// since the sheet already fetched the full [Recipient]. There's no
  /// auto-loaded default anymore — this is the ONLY way `state.recipient`
  /// ever gets set.
  void setRecipient(Recipient recipient) {
    state = state.copyWith(recipient: recipient);
  }

  Future<void> loadWallets() async {
  state = state.copyWith(loadingWallets: true);
  try {
    final wallets = await _repository.getWallets();
    state = state.copyWith(
      wallets: wallets,
      loadingWallets: false,
      selectedWallet: wallets.isNotEmpty ? wallets.first : null,
    );
  } catch (e) {
    state = state.copyWith(loadingWallets: false);
  }
}

void selectWallet(Wallet wallet) {
  state = state.copyWith(selectedWallet: wallet);
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
